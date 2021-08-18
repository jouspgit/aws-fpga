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

#include <sys/time.h>

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
#define N_DDR 4

// axi mstr DMA registers : 

// Towards JPEG-XS (Stream)
#define MM2S_DMACR         0x00UL // Control register
#define MM2S_DMASR         0x04UL // Status register
#define MM2S_SA            0x18UL // Source address low
#define MM2S_SA_MSB        0x1cUL // Source address high
#define MM2S_LENGTH        0x28UL // Length of transfer
// Towards DDR (AXI4)
#define S2MM_DMACR         0x30UL // Control register
#define S2MM_DMASR         0x34UL // Status register
#define S2MM_DA            0x48UL // Destination address low
#define S2MM_DA_MSB        0x4cUL // Destination address high
#define S2MM_LENGTH        0x58UL // Length of transfer


void usage(const char* program_name);
int custom_hwsw_cosim(int slot_id, size_t buffer_size);
int dma_example_hwsw_cosim(int slot_id, size_t buffer_size);
int dma_readback(int slot_id, size_t buffer_size);

void print_buffer(uint8_t *buffer, size_t buffer_size);
void fill_buffer_custom(uint8_t *buf, size_t size);

static inline int do_dma_read(int fd, uint8_t *buffer, size_t size,
    uint64_t address, int channel, int slot_id);
static inline int do_dma_write(int fd, uint8_t *buffer, size_t size,
    uint64_t address, int channel, int slot_id);


#if !defined(SV_TEST)
/* use the stdout logger */
const struct logger *logger = &logger_stdout;
#else
# define log_error(...) printf(__VA_ARGS__); printf("\n")
# define log_info(...) printf(__VA_ARGS__); printf("\n")
#endif

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
    size_t buffer_size;
#if defined(SV_TEST)
    buffer_size = 256; // bytes
#else
    //buffer_size = 1ULL << 24; // buffer of 16M bytes
    //buffer_size = 1ULL << 9; // buffer of 512 bytes
    //buffer_size = 1ULL << 14; // buffer of 16kiB
    buffer_size = 1ULL << 13; // buffer of 8kiB
#endif
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

#endif

    struct timeval tvalBefore, tvalAfter;
    gettimeofday(&tvalBefore, NULL);

    rc = dma_example_hwsw_cosim(slot_id, buffer_size);
    fail_on(rc, out, "DMA example failed"); // write in DDR //+ readback quickly

    rc = custom_hwsw_cosim(slot_id, buffer_size); //  engage JPEG DMA modification
    fail_on(rc, out, "Custom hw/sw co-simulation failed");

    rc = dma_readback(slot_id, buffer_size); //  readback the modified data.
    fail_on(rc, out, "Readback failed");

    gettimeofday (&tvalAfter, NULL);

    long int time_spent = ((tvalAfter.tv_sec - tvalBefore.tv_sec)*1000000L
           +tvalAfter.tv_usec) - tvalBefore.tv_usec;

    printf("Time in microseconds: %ld microseconds\n",time_spent);
    long double throughput = (long double) buffer_size*N_DDR / (time_spent);
    printf("Speed: %Lf MB/s\n\n", throughput);

out:

#if !defined(SV_TEST)
    return rc;
    fpga_mgmt_close();
#else
    if (rc != 0) {
        printf("TEST FAILED \n");
    }
    else {
        printf("TEST PASSED \n");
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
    printf("usage: %s [--slot <slot>]\n", program_name);
}

int dma_example_hwsw_cosim(int slot_id, size_t buffer_size)
{
    int write_fd, read_fd, dimm, rc;

    write_fd = -1;
    read_fd = -1;

    uint8_t *write_buffer = malloc(buffer_size);
    uint8_t *read_buffer = malloc(buffer_size);
    if (write_buffer == NULL || read_buffer == NULL) {
        rc = -ENOMEM;
        goto out;
    }

    printf("Memory has been allocated, initializing DMA and filling the buffer of size : %zu\n", buffer_size);
#if !defined(SV_TEST)
    read_fd = fpga_dma_open_queue(FPGA_DMA_XDMA, slot_id,
        /*channel*/ 0, /*is_read*/ true);
    fail_on((rc = (read_fd < 0) ? -1 : 0), out, "unable to open read dma queue");

    write_fd = fpga_dma_open_queue(FPGA_DMA_XDMA, slot_id,
        /*channel*/ 0, /*is_read*/ false);
    fail_on((rc = (write_fd < 0) ? -1 : 0), out, "unable to open write dma queue");
#else
    setup_send_rdbuf_to_c(read_buffer, buffer_size);
    printf("Starting DDR init...\n");
    init_ddr();
    //deselect_atg_hw();
    printf("Done DDR init...\n");
#endif
    printf("filling buffer with custom data...\n") ;

    //fill_buffer_custom(write_buffer, buffer_size);
    rc = fill_buffer_urandom(write_buffer, buffer_size);
    fail_on(rc, out, "unable to initialize buffer");

    printf("Values inside the write buffer are : \n\n");
    print_buffer(write_buffer, buffer_size);


    printf("Now performing the DMA transactions...\n");
    for (dimm = 0; dimm < N_DDR; dimm++) {
        rc = do_dma_write(write_fd, write_buffer, buffer_size,
            dimm * MEM_16G+0x200000000, dimm, slot_id);
        fail_on(rc, out, "DMA write failed on DIMM: %d", dimm);
        printf("Address : %llx\n", dimm * MEM_16G+0x200000000);
    }

    bool passed = true;
    /*
    for (dimm = 0; dimm < N_DDR; dimm++) {
        rc = do_dma_read(read_fd, read_buffer, buffer_size,
            dimm * MEM_16G+0x200000000, dimm, slot_id);
        fail_on(rc, out, "DMA read failed on DIMM: %d", dimm);

        //printf("Values inside the write buffer readback are : \n\n");
        //print_buffer(read_buffer, buffer_size);

        uint64_t differ = buffer_compare(read_buffer, write_buffer, buffer_size);
        if (differ != 0) {
            log_error("DIMM %d failed with %lu bytes which differ", dimm, differ);
            passed = false;
        } else {
            log_info("DIMM %d passed!", dimm);
        }
    }*/
    rc = (passed) ? 0 : 1;

out:
    if (write_buffer != NULL) {
        free(write_buffer);
    }
    if (read_buffer != NULL) {
        free(read_buffer);
    }
#if !defined(SV_TEST)
    if (write_fd >= 0) {
        close(write_fd);
    }
    if (read_fd >= 0) {
        close(read_fd);
    }
#endif
    /* if there is an error code, exit with status 1 */
    return (rc != 0 ? 1 : 0);
}

int custom_hwsw_cosim(int slot_id, size_t buffer_size)
{
    int rc, dimm;
    int pf_id = FPGA_APP_PF;
    uint64_t offset, address;
    uint32_t value;

    /* Accessing the Dma configuration registers via AppPF BAR0, which maps to sh_cl_ocl_ AXI-Lite bus between AWS FPGA Shell and the CL*/
    int bar_id = APP_PF_BAR0; // Connect to OCL port.
    uint32_t flags =0;// no flags
    pci_bar_handle_t handle = PCI_BAR_HANDLE_INIT;

    //Initialize the pci library, actually useless

    fpga_pci_init();

    rc = fpga_pci_attach(slot_id, pf_id, bar_id, flags, &handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d and BAR0", slot_id);

    //--------------------------------------------------------------------------
    // Here starts the code that configures the axi mstr DMA for a transfer.



    for (dimm = 0; dimm < N_DDR; dimm++) {

    printf("\nConfiguring DMA for MM2S DMA operation.\n");
        offset = MM2S_DMACR;
        value = 0x1; // Set RS bit to 1 (run/stop), no interrupts generation
        rc = fpga_pci_poke(handle, offset, value); //Write a value to a register.
        fail_on(rc, out, "Unable to write to the fpga (MM2S_DMACR)!");

        offset = MM2S_SA_MSB; // write upper source address (DDR, 0x200000000
        address = dimm * MEM_16G+0x200000000;
        value = address>>32;
        rc = fpga_pci_poke(handle, offset, value);
        fail_on(rc, out, "Unable to write to the fpga (MM2S_SA_MSB)!");
        printf("Adress : %x\n",value);

        offset = MM2S_SA; // write lower source address
        value = 0x0;
        rc = fpga_pci_poke(handle, offset, value);
        fail_on(rc, out, "Unable to write to the fpga (MM2S_SA)!");

        offset = MM2S_LENGTH; // set transfer length
        value = (uint32_t) buffer_size ;
        rc = fpga_pci_poke(handle, offset, value);
        fail_on(rc, out, "Unable to write to the fpga (MM2S_LENGTH)!");


    //}


    printf("Configuring DMA for S2MM DMA operation.\n");

    //for (dimm = 0; dimm < N_DDR; dimm++) {

        offset = S2MM_DMACR;
        value = 0x1;  // Set RS bit to 1 (run/stop), no interrupts generation
        rc = fpga_pci_poke(handle, offset, value);
        fail_on(rc, out, "Unable to write to the fpga (S2MM_DMACR)!");

        offset = S2MM_DA_MSB; // write upper destination address (DDR)
        address = dimm * MEM_16G + 0x0;
        value = address>>32;
        rc = fpga_pci_poke(handle, offset, value);
        fail_on(rc, out, "Unable to write to the fpga (S2MM_DA_MSB)!");
        printf("Adress : %x\n",value);

        offset = S2MM_DA; // write lower destination address (DDR)
        value = 0x0;
        rc = fpga_pci_poke(handle, offset, value);
        fail_on(rc, out, "Unable to write to the fpga (S2MM_DA)!");

        offset = S2MM_LENGTH; // set transfer length
        value = (uint32_t) buffer_size ;
        rc = fpga_pci_poke(handle, offset, value);
        fail_on(rc, out, "Unable to write to the fpga (S2MM_LENGTH)!");
        //usleep(100000);
    }


    //usleep(1000000);
    //delay ? or waiting in a loop?


    //---------------------Wait and Check (unused for now)----------------------
    /*
    // Wait for the busy status to be cleared

    //int timeout;
    //uint32_t find_ok = 0;
    //uint32_t find_ko = 0;
    //uint32_t busy = 0;
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
    }
    return (rc != 0 ? 1 : 0);
    // functions past line 184 seem to maybe be useful but hard to say
}


int dma_readback(int slot_id, size_t buffer_size)
{
    int read_fd, dimm, rc;

    read_fd = -1;

    uint8_t *read_buffer = malloc(buffer_size);
    if (read_buffer == NULL) {
        rc = -ENOMEM;
        goto out;
    }

    printf("Memory has been allocated for readback.\n");
#if !defined(SV_TEST)
    read_fd = fpga_dma_open_queue(FPGA_DMA_XDMA, slot_id,
        /*channel*/ 0, /*is_read*/ true);
    fail_on((rc = (read_fd < 0) ? -1 : 0), out, "unable to open read dma queue");
#else
    setup_send_rdbuf_to_c(read_buffer, buffer_size);
#endif
    
    printf("Now performing the DMA readbacks...\n");


    for (dimm = 0; dimm < N_DDR; dimm++) {
        rc = do_dma_read(read_fd, read_buffer, buffer_size,
            dimm * MEM_16G, dimm, slot_id); // modified readback adress, works
        fail_on(rc, out, "DMA read failed on DIMM: %d", dimm);

        printf("Values inside the data readback buffer are : \n\n");
        print_buffer(read_buffer, buffer_size);

    }
    bool passed = true;
    rc = (passed) ? 0 : 1;

out:
    if (read_buffer != NULL) {
        free(read_buffer);
    }
#if !defined(SV_TEST)
    if (read_fd >= 0) {
        close(read_fd);
    }
#endif
    /* if there is an error code, exit with status 1 */
    return (rc != 0 ? 1 : 0);
}


static inline int do_dma_read(int fd, uint8_t *buffer, size_t size,
    uint64_t address, int channel, int slot_id)
{
#if defined(SV_TEST)
    sv_fpga_start_cl_to_buffer(slot_id, channel, size, (uint64_t) buffer, address);
    return 0;
#else
    return fpga_dma_burst_read(fd, buffer, size, address);
#endif
}

static inline int do_dma_write(int fd, uint8_t *buffer, size_t size,
    uint64_t address, int channel, int slot_id)
{
#if defined(SV_TEST)
    sv_fpga_start_buffer_to_cl(slot_id, channel, size, (uint64_t) buffer, address);
    return 0;
#else
    return fpga_dma_burst_write(fd, buffer, size, address);
#endif
}

void fill_buffer_custom(uint8_t *buf, size_t size)
{
  off_t i = 0;
  uint8_t value=1;
    while ( i < size ) {
      *(buf+i) = value; // writes a byte
      i ++;
      if (i%4==0)
      {
        value = !value; // switch between 0 an 1
      }
        
    }

}

void print_buffer(uint8_t *buffer, size_t buffer_size){

#if defined(SV_TEST)
/* Big endian bit order for Vivado wave comparisons.
   Can lead to segmentation errors if used in non SV_TEST environment
   because of size_t being unsigned. */

        for (int i = buffer_size-1; i >= 0; i--){
            if(i%64==0){
                printf("%02x\n",buffer[i]);
            }else{
                printf("%02x",buffer[i]);
            }
        }
        printf("\n");

#else
/* "Normal" little endian bit order for C software FPGA runs. */

        for (size_t i = 0; i < buffer_size; ++i){
            if(i%64==0){
                printf("\n%02x",buffer[i]);
            }else{
                printf("%02x",buffer[i]);
            }
        }
        printf("\n\n");
#endif
}

