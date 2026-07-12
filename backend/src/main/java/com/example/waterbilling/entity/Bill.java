package com.example.waterbilling.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(name = "bills")
public class Bill {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @Column(name = "bill_code", nullable = false, unique = true, length = 50)
    private String billCode;

    @Column(name = "bill_date", nullable = false)
    private LocalDateTime date;

    @Column(name = "old_reading", nullable = false)
    private Integer oldReading;

    @Column(name = "new_reading", nullable = false)
    private Integer newReading;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal consumption;

    @Column(name = "unit_price", nullable = false, precision = 18, scale = 2)
    private BigDecimal unitPrice;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal vat;

    @Column(name = "total_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal totalAmount;

    @Column(name = "image_path", length = 1000)
    private String imagePath;

    @Column(name = "is_synced", nullable = false)
    private Boolean synced = false;

    @Column(name = "is_paid", nullable = false)
    private Boolean paid = false;
}
