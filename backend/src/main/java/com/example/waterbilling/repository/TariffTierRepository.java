package com.example.waterbilling.repository;

import com.example.waterbilling.entity.TariffTier;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TariffTierRepository extends JpaRepository<TariffTier, Long> {
    List<TariffTier> findByIsActiveTrueOrderByFromM3Asc();
}
