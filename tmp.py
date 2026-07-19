def calculate_ks128_constants(i):
    # Lấy 5 bit của i+1 và 0
    ci_plus_1 = (i + 1) & 0x1F
    c0 = 0 & 0x1F
    
    # Thực hiện ghép bit (dịch bit sang trái tương ứng với vị trí)
    # Vị trí dịch: 27, 22, 17, 15, 10, 5, 0
    concatenated_val = (ci_plus_1 << 27) | \
                       (c0 << 22) | \
                       (ci_plus_1 << 17) | \
                       (0 << 15) | \
                       (ci_plus_1 << 10) | \
                       (c0 << 5) | \
                       (ci_plus_1 << 0)
                       
    # Hằng số từ công thức
    magic_constant = 0x6547a98b
    
    # XOR
    result = concatenated_val ^ magic_constant
    
    # Tách 16-bit cao và 16-bit thấp
    con_2i = (result >> 16) & 0xFFFF
    con_2i_plus_1 = result & 0xFFFF
    
    return con_2i, con_2i_plus_1

# Ví dụ tính 5 vòng đầu tiên (từ i=0 đến i=4)
for i in range(61):
    c1, c2 = calculate_ks128_constants(i)
    print(f"i = {i}: con_{2*i} = 0x{c1:04X}, con_{2*i+1} = 0x{c2:04X}")