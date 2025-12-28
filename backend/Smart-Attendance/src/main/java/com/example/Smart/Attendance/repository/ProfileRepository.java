package com.example.Smart.Attendance.repository;

import com.example.Smart.Attendance.model.Profile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ProfileRepository extends JpaRepository<Profile, Long> {

    // Matches field: private String studentName;
    Optional<Profile> findByStudentName(String studentName);
}