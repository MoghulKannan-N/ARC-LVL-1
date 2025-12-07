package com.example.Smart.Attendance.repository;

import com.example.Smart.Attendance.model.Profile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProfileRepository extends JpaRepository<Profile, Long> {
    Profile findByStudentName(String studentName);
}
