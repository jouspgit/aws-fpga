// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.

#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <malloc.h>
#include <poll.h>
//-------------------------//
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/stat.h>
#include <linux/uaccess.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/pci.h>

#include <linux/slab.h>
//--------------------------//
#include <utils/sh_dpi_tasks.h>

#ifdef SV_TEST
# include <fpga_pci_sv.h>
#else
# include <fpga_pci.h>
# include <fpga_mgmt.h>
# include "fpga_dma.h"
# include <utils/lcd.h>
#endif

#include "test_dram_dma_common.h"

#define MEM_16G           (1ULL << 34)
// Defines from the test_peek_poke_sv
#define CFG_REG           0x0ULL
#define CNTL_REG          0x08ULL
#define NUM_INST          0x10ULL
#define MAX_RD_REQ        0x14ULL

#define WR_INSTR_INDEX    0x1cULL
#define WR_ADDR_LOW       0x20ULL
#define WR_ADDR_HIGH      0x24ULL
#define WR_DATA           0x28ULL
#define WR_LEN            0x2cULL

#define RD_INSTR_INDEX    0x3cULL
#define RD_ADDR_LOW       0x40ULL
#define RD_ADDR_HIGH      0x44ULL
#define RD_DATA           0x48ULL
#define RD_LEN            0x4cULL

#define RD_ERR            0xb0ULL
#define RD_ERR_ADDR_LOW   0xb4ULL
#define RD_ERR_ADDR_HIGH  0xb8ULL
#define RD_ERR_INDEX      0xbcULL

#define WR_CYCLE_CNT_LOW  0xf0ULL
#define WR_CYCLE_CNT_HIGH 0xf4ULL
#define RD_CYCLE_CNT_LOW  0xf8ULL
#define RD_CYCLE_CNT_HIGH 0xfcULL

#define WR_START_BIT      0x1UL
#define RD_START_BIT      0x2UL

#define ATG_BUFFER_SIZE 4096 // pages of 4KB

void usage(const char* program_name);
int custom_hwsw_cosim(int slot_id);

int check_afi_ready(int slot);

unsigned char *atg_buffer;
unsigned char *phys_atg_buffer;


#if !defined(SV_TEST)
/* use the stdout logger */
const struct logger *logger = &logger_stdout;
#else
# define log_error(...) cosim_printf(__VA_ARGS__); cosim_printf("\n")
# define log_info(...) cosim_printf(__VA_ARGS__); cosim_printf("\n")
#endif

/*
 * pci_vendor_id and pci_device_id values below are Amazon's and avaliable to use for a given FPGA slot. 
 * Users may replace these with their own if allocated to them by PCI SIG
 */
static uint16_t pci_vendor_id = 0x1D0F; /* Amazon PCI Vendor ID */
static uint16_t pci_device_id = 0xF000; /* PCI Device ID preassigned by Amazon for F1 applications */


/* Main will be different for different simulators and also for C. The
 * definition is in sdk/userspace/utils/include/sh_dpi_tasks.h file */
#if defined(SV_TEST) && defined(INT_MAIN)
/* For cadence and questa simulators main has to return some value */
int test_main(uint32_t *exit_code)

#elif defined(SV_TEST)
void test_main(uint32_t *exit_code)

#else 
int main(int argc, char **argv)

#endif
{
    
    /* The statements within SCOPE ifdef below are needed for HW/SW
     * co-simulation with VCS */
#if defined(SCOPE)
    svScope scope;
    scope = svGetScopeFromName("tb");
    svSetScope(scope);
#endif

    int rc;
    int slot_id = 0;

#if !defined(SV_TEST)
    switch (argc) {
    case 1:
        break;
    case 3:
        sscanf(argv[2], "%x", &slot_id);
        break;
    default:
        usage(argv[0]);
        return 1;
    }

    /* setup logging to print to stdout */
    rc = log_init("test_custom_hwsw_cosim");
    fail_on(rc, out, "Unable to initialize the log.");
    rc = log_attach(logger, NULL, 0);
    fail_on(rc, out, "%s", "Unable to attach to the log.");

    /* initialize the fpga_plat library */
    rc = fpga_mgmt_init();
    fail_on(rc, out, "Unable to initialize the fpga_mgmt library");

    rc = check_afi_ready(slot_id);
    fail_on(rc, out, "AFI not ready");

#endif

    rc = custom_hwsw_cosim(slot_id);
    fail_on(rc, out, "Custom hw/sw co-simulation failed");


out:

#if !defined(SV_TEST)
    return rc;
    fpga_mgmt_close();
#else
    if (rc != 0) {
        cosim_printf("TEST FAILED \n");
    }
    else {
        cosim_printf("TEST PASSED \n");
    }
    /* For cadence and questa simulators main has to return some value */
    #ifdef INT_MAIN
    *exit_code = 0;
    return 0;
    #else
    *exit_code = 0;
    #endif
#endif
}

void usage(const char* program_name) {
    cosim_printf("usage: %s [--slot <slot>]\n", program_name);
}
int custom_hwsw_cosim(int slot_id)
{   
    int rc;
    int timeout;
    uint32_t find_ok = 0;
    uint32_t find_ko = 0;
    uint32_t busy = 0;
	int pf_id = FPGA_APP_PF;

    /* Accessing the CL registers via AppPF BAR0, which maps to sh_cl_ocl_ AXI-Lite bus between AWS FPGA Shell and the CL*/
	int bar_id = APP_PF_BAR0; //to enable the pcim transfer  (peek_ocl)
	uint32_t flags =0;// no flags
	pci_bar_handle_t handle = PCI_BAR_HANDLE_INIT;

	// Preparing memory pages for operations
	atg_buffer = kmalloc(ATG_BUFFER_SIZE, GFP_DMA | GFP_USER);
	phys_atg_buffer = (unsigned char *)virt_to_phys(atg_buffer); 
    
    //Initialize the pci library, actually useless

    fpga_pci_init();

    rc = fpga_pci_attach(slot_id, pf_id, bar_id, flags, &handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d and BAR0", slot_id);
   
    //--------------------------------------------------------------------------
    //Here we should launch the code that activates the counter and lets the 
    //custom data do its thing
    cosim_printf("\nEnabling the PCIM transfer");

    uint64_t offset = CFG_REG; // TO CHANGE, this is simply copied from sv test
    uint32_t atg_value = 0x1000018; // Enable Incr ID mode, Sync mode, and Read Compare
    
    rc = fpga_pci_poke(handle, offset, atg_value); //Write a value to a register.
    fail_on(rc, out, "Unable to write to the fpga (CFG_REG)!");

    offset = MAX_RD_REQ;
    atg_value = 0xf;
    rc = fpga_pci_poke(handle, offset, atg_value);
    fail_on(rc, out, "Unable to write to the fpga (MAX_RD_REQ)!");

    offset = WR_INSTR_INDEX;
    atg_value = 0x0;
    rc = fpga_pci_poke(handle, offset, atg_value);
    fail_on(rc, out, "Unable to write to the fpga (WR_INSTR_INDEX)!");


    offset = WR_ADDR_LOW;
    //atg_value = 0x12340000;
    atg_value = ((uint32_t)(unsigned long)phys_atg_buffer & 0xffffffffl); // give the address of buffer we created with kmalloc
    rc = fpga_pci_poke(handle, offset, atg_value);
    fail_on(rc, out, "Unable to write to the fpga (WR_ADDR_LOW)!");

    offset = WR_ADDR_HIGH;
    //atg_value = 0x0;
    atg_value=(uint32_t)((unsigned long)phys_atg_buffer >> 32l);
    rc = fpga_pci_poke(handle, offset, atg_value);
    fail_on(rc, out, "Unable to write to the fpga (WR_ADDR_HIGH)!");

    offset = WR_DATA;
    atg_value = 0x6c93af50;  // TO CHANGE, value to launch the transac.
    rc = fpga_pci_poke(handle, offset, atg_value);
    fail_on(rc, out, "Unable to write to the fpga (WR_DATA)!");

    offset = WR_LEN;
    atg_value = 0x0;
    rc = fpga_pci_poke(handle, offset, atg_value);
    fail_on(rc, out, "Unable to write to the fpga (WR_LEN)!");



    offset = NUM_INST;
    atg_value = 0x0;
    rc = fpga_pci_poke(handle, offset, atg_value);
    fail_on(rc, out, "Unable to write to the fpga (NUM_INST)!");

    offset = CNTL_REG;
    atg_value = WR_START_BIT;
    rc = fpga_pci_poke(handle, offset, atg_value);
    fail_on(rc, out, "Unable to write to the fpga (CNTL_REG, WR_START_BIT)!");

    //delay ? or waiting in a loop?
    // we chec


    //--------------------------------------------------------------------------
    //Here we peek at the value inside the shell
    unsigned long nbytes = ATG_BUFFER_SIZE;//to copy 
    char buf;
 
  	copy_to_user(&buf, atg_buffer, nbytes);


    /*//-----------------------------useles code in sim---------------------------
    bar_id = APP_PF_BAR4;
    rc = fpga_pci_attach(slot_id, pf_id, bar_id, flags, &handle);   
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d and BAR4", slot_id);

    offset = 0x12340000; // TO CHANGE, find PCIM BAR
    uint32_t data_value; // output value of counter

	*////--------------------------------------------------------------------------


    //We could use the peek8 for only 8 bits, but it is only relevant in my
    //program and it doesn't exist while hw/sw cosim.
    
    fpga_pci_peek(handle, offset, &data_value); //Read a value from a register.
    cosim_printf("\nValue received from custom data : %x \n", buf);

    //--------------------------------------------------------------------------
    /*
    // Wait for the busy status to be cleared
    busy = 1;
    while(busy == 1) {
    if(timeout == 10) {
      printf("Timeout - Something went wrong with the HW. Please do\n");
      printf("\t\tsudo fpga-clear-local-image -S %d\n", slot_id);
      printf("And reload your AFI\n");
      printf("\t\tsudo fpga-load-local-image -S %d -I agfi-xxxxxxxxxxxxxxxxx\n", slot_id);
      return 1;
    }
    if (timeout) {
      printf("Please wait, it may take time ...\n");
    }
    // Wait for the HW to process
    usleep(1000000);
    timeout++;

    // Read
    rc = fpga_pci_peek(pci_bar_handle, URAM_REG_ADDR, &value);
    fail_on(rc, out, "Unable to read read from the fpga !");
    find_ok = value >> 31;
    find_ko = (value >> 30) & 0x00000001;
    busy = (value >> 29) & 0x00000001;
    value = value & 0x1fffffff;
    printf("Read 0x%08x find_ok=%d find_ko=%d, busy=%d\n", value, find_ok, find_ko, busy);
  }
  
  if(find_ok == 1) {
    if(del_info == 1) {
      printf("Deletion OK : The value 0x%08x has been deleted successfully\n", value); 
    } else {
      printf("Find OK : The value 0x%08x is present in the URAM\n", value); 
    }
  } else {
    if(find_ko == 1) {
      printf("Find KO : The value 0x%08x is NOT present in the URAM\n", value); 
    } else {
      printf("The value 0x%08x has been added to the URAM successfully\n", value);
    }
  }*/
   
    out:
    if (handle>=0)
    {
        rc = fpga_pci_detach(handle); //  Detach from an FPGA memory space.
        if (rc) {
        printf("Failure while detaching from the fpga.\n");
        }
    kfree(atg_buffer);
    }
    

    return (rc != 0 ? 1 : 0);
    // functions past line 184 seem to maybe be useful but hard to say
}

/* As HW simulation test is not run on a AFI, the below function is not valid */
#ifndef SV_TEST

/*
 * check if the corresponding AFI for hello_world is loaded
 */

int check_afi_ready(int slot_id) {
  struct fpga_mgmt_image_info info = {0}; 
  int rc;
 
  /* get local image description, contains status, vendor id, and device id. */
  rc = fpga_mgmt_describe_local_image(slot_id, &info,0);
  fail_on(rc, out, "Unable to get AFI information from slot %d. Are you running as root?",slot_id);
 
  /* check to see if the slot is ready */
  if (info.status != FPGA_STATUS_LOADED) {
    rc = 1;
    fail_on(rc, out, "AFI in Slot %d is not in READY state !", slot_id);
  }
 
  //printf("AFI PCI  Vendor ID: 0x%x, Device ID 0x%x\n",
  //    info.spec.map[FPGA_APP_PF].vendor_id,
  //    info.spec.map[FPGA_APP_PF].device_id);
 
  /* confirm that the AFI that we expect is in fact loaded */
  if (info.spec.map[FPGA_APP_PF].vendor_id != pci_vendor_id ||
      info.spec.map[FPGA_APP_PF].device_id != pci_device_id) {
      printf("AFI does not show expected PCI vendor id and device ID. If the AFI "
             "was just loaded, it might need a rescan. Rescanning now.\n");
 
      rc = fpga_pci_rescan_slot_app_pfs(slot_id);
      fail_on(rc, out, "Unable to update PF for slot %d",slot_id);
      /* get local image description, contains status, vendor id, and device id. */
      rc = fpga_mgmt_describe_local_image(slot_id, &info,0);
      fail_on(rc, out, "Unable to get AFI information from slot %d",slot_id);
 
      printf("AFI PCI  Vendor ID: 0x%x, Device ID 0x%x\n",
          info.spec.map[FPGA_APP_PF].vendor_id,
          info.spec.map[FPGA_APP_PF].device_id);
 
      /* confirm that the AFI that we expect is in fact loaded after rescan */
      if (info.spec.map[FPGA_APP_PF].vendor_id != pci_vendor_id ||
           info.spec.map[FPGA_APP_PF].device_id != pci_device_id) {
          rc = 1;
          fail_on(rc, out, "The PCI vendor id and device of the loaded AFI are not "
                           "the expected values.");
      }
  }
  
  return rc;
 
out:
  return 1;
}

#endif


