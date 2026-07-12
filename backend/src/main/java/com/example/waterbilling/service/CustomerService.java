package com.example.waterbilling.service;

import com.example.waterbilling.dto.CustomerDto;
import com.example.waterbilling.entity.AppUser;
import com.example.waterbilling.entity.UserRole;
import com.example.waterbilling.entity.CollectionStatus;
import com.example.waterbilling.entity.Customer;
import com.example.waterbilling.repository.AppUserRepository;
import com.example.waterbilling.repository.CustomerRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CustomerService {
    private final CustomerRepository customerRepository;
    private final AppUserRepository appUserRepository;
    private final PasswordEncoder passwordEncoder;

    public CustomerService(CustomerRepository customerRepository, AppUserRepository appUserRepository, PasswordEncoder passwordEncoder) {
        this.customerRepository = customerRepository;
        this.appUserRepository = appUserRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public List<CustomerDto> getAll(String query) {
        List<Customer> customers = query == null || query.isBlank()
                ? customerRepository.findAll()
                : customerRepository.findByNameContainingIgnoreCaseOrCodeContainingIgnoreCase(query, query);
        return customers.stream().map(CustomerDto::from).toList();
    }

    public CustomerDto getById(Long id) {
        return CustomerDto.from(findEntity(id));
    }

    @Transactional
    public CustomerDto create(CustomerDto dto) {
        customerRepository.findByCode(dto.code()).ifPresent(existing -> {
            throw new IllegalArgumentException("Mã khách hàng đã tồn tại");
        });

        Customer customer = new Customer();
        customer.setCode(dto.code());
        customer.setName(dto.name());
        customer.setAddress(dto.address());
        customer.setPhone(dto.phone());
        customer.setCurrentReading(dto.currentReading() == null ? 0 : dto.currentReading());
        customer.setStatus(dto.statusEnum());
        Customer savedCustomer = customerRepository.save(customer);

        // Tạo tài khoản đăng nhập app user tự động cho khách hàng
        AppUser appUser = new AppUser();
        // Dùng mã khách hàng (dạng viết thường) làm username đăng nhập
        appUser.setUsername(savedCustomer.getCode().toLowerCase());
        appUser.setFullName(savedCustomer.getName());
        appUser.setPasswordHash(passwordEncoder.encode("123456"));
        appUser.setRole(UserRole.USER);
        appUser.setEmail(null);
        appUser.setPhone(savedCustomer.getPhone());
        appUser.setCustomer(savedCustomer);
        appUserRepository.save(appUser);

        return CustomerDto.from(savedCustomer);
    }

    @Transactional
    public CustomerDto update(Long id, CustomerDto dto) {
        Customer customer = findEntity(id);
        customer.setCode(dto.code());
        customer.setName(dto.name());
        customer.setAddress(dto.address());
        customer.setPhone(dto.phone());
        customer.setCurrentReading(dto.currentReading());
        customer.setStatus(dto.statusEnum());
        return CustomerDto.from(customer);
    }

    @Transactional
    public CustomerDto updateStatus(Long id, Integer status) {
        Customer customer = findEntity(id);
        customer.setStatus(CollectionStatus.fromFlutterIndex(status));
        return CustomerDto.from(customer);
    }

    @Transactional
    public CustomerDto updateReading(Long id, Integer newReading) {
        Customer customer = findEntity(id);
        if (newReading < customer.getCurrentReading()) {
            throw new IllegalArgumentException("Chỉ số mới không được nhỏ hơn chỉ số cũ");
        }
        customer.setCurrentReading(newReading);
        customer.setStatus(CollectionStatus.COMPLETED);
        return CustomerDto.from(customer);
    }

    public Customer findEntity(Long id) {
        return customerRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Không tìm thấy khách hàng id=" + id));
    }
}
