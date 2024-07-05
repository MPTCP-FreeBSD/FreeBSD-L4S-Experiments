import ctypes
import os

# Define the struct data as specified
class Data(ctypes.Structure):
    _fields_ = [
        ("drop_prob", ctypes.c_uint),
        ("current_qdelay", ctypes.c_int),
        ("qdelay_old", ctypes.c_int),
        ("avg_dq_time", ctypes.c_uint),
        ("tot_bytes", ctypes.c_uint),
        ("drops", ctypes.c_uint)
    ]

# System call numbers (you'll need to replace these with the actual syscall numbers)
SYS_DRL_UPDATE_PROB = 588  # Placeholder, replace with actual syscall number
SYS_DRL_GET_BUFFER = 589   # Placeholder, replace with actual syscall number

# Load the C standard library (libc)
libc = ctypes.CDLL("libc.so.7")

# Define the system calls using ctypes
def drl_update_prob(prob):
    return libc.syscall(SYS_DRL_UPDATE_PROB, ctypes.c_int(prob))

def drl_get_buffer():
    buffer = Data()
    size = ctypes.c_int(ctypes.sizeof(buffer))
    ret = libc.syscall(SYS_DRL_GET_BUFFER, ctypes.byref(buffer), ctypes.byref(size))
    return ret, buffer, size.value

def main():
    prob = 10  # Example probability value
    ret = drl_update_prob(prob)
    if ret < 0:
        print(f"Error calling drl_update_prob: {os.strerror(ctypes.get_errno())}")
        return
    print(f"drl_update_prob returned: {ret}")

    ret, buffer, size = drl_get_buffer()
    if ret < 0:
        print(f"Error calling drl_get_buffer: {os.strerror(ctypes.get_errno())}")
        return
    print(f"drl_get_buffer returned: {ret}")
    print(f"Buffer size: {size}")
    print("Buffer details:")
    print(f"drop_prob: {buffer.drop_prob}")
    print(f"current_qdelay: {buffer.current_qdelay}")
    print(f"qdelay_old: {buffer.qdelay_old}")
    print(f"avg_dq_time: {buffer.avg_dq_time}")
    print(f"tot_bytes: {buffer.tot_bytes}")
    print(f"drops: {buffer.drops}")

if __name__ == "__main__":
    main()
