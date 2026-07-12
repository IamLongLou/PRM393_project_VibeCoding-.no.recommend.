package com.example.waterbilling.config;

import com.example.waterbilling.entity.AppUser;
import com.example.waterbilling.entity.Customer;
import com.example.waterbilling.entity.UserRole;
import com.example.waterbilling.repository.AppUserRepository;
import com.example.waterbilling.repository.CustomerRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {
    private final AppUserRepository userRepository;
    private final CustomerRepository customerRepository;
    private final PasswordEncoder passwordEncoder;

    public DataInitializer(AppUserRepository userRepository, CustomerRepository customerRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.customerRepository = customerRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
//        createUser("admin", "admin123", "Quản Trị Viên", UserRole.ADMIN, "admin@water.com", "0987654321", null);
//        createUser("nhanvien01", "123456", "Nguyễn Văn A", UserRole.STAFF, "nguyenvana@gmail.com", "0912345678", null);
        // createUser("khachhang16", "123456", "Lê Minh Triết", UserRole.USER, "trietle@gmail.com", "0901234567", "KH001");
//        createUser("abc", "123", "Khách Hàng Mới", UserRole.USER, "abc@gmail.com", "0900000000", "KH002");
    }

    private void createUser(String username, String password, String fullName, UserRole role, String email, String phone, String customerCode) {
        if (userRepository.findByUsername(username).isPresent()) {
            return;
        }
        AppUser user = new AppUser();
        user.setUsername(username);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setFullName(fullName);
        user.setRole(role);
        user.setEmail(email);
        user.setPhone(phone);
        if (customerCode != null) {
            customerRepository.findByCode(customerCode).ifPresent(user::setCustomer);
        }
        userRepository.save(user);
    }
}
