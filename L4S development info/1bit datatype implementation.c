#include <stdio.h>

// Define the struct with a 1-bit field
struct my_struct {
    unsigned int queue_type : 1; // 1-bit field
};

int main() {
    struct my_struct example;

    // Set queue_type to 0 (classic)
    example.queue_type = 0;
    if (example.queue_type == 0) {
        printf("Queue type is classic.\n");
    } else {
        printf("Queue type is L4S.\n");
    }

    // Set queue_type to 1 (L4S)
    example.queue_type = 1;
    if (example.queue_type == 0) {
        printf("Queue type is classic.\n");
    } else {
        printf("Queue type is L4S.\n");
    }

    return 0;
}
