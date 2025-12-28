package com.example.Smart.Attendance.service;

import com.example.Smart.Attendance.model.Profile;
import com.example.Smart.Attendance.model.Student;
import com.example.Smart.Attendance.repository.ProfileRepository;
import com.example.Smart.Attendance.repository.StudentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class ProfileService {

    @Autowired
    private ProfileRepository profileRepository;

    @Autowired
    private StudentRepository studentRepository;

    // ✅ Get or create profile by student name
    public Profile getProfileByName(String studentName) {
        // Fast path: try to fetch profile directly by studentName (one SQL, joins student when needed)
        Optional<Profile> existing = profileRepository.findByStudentName(studentName);
        if (existing.isPresent()) {
            return existing.get();
        }

        // Fallback: profile not found — fetch Student and create Profile
        Student student = studentRepository.findByName(studentName)
                .orElseThrow(() -> new RuntimeException("Student not found: " + studentName));

        Profile newProfile = new Profile(student);
        newProfile.setStudent(student);
        newProfile.setStudentName(student.getName());
        return profileRepository.save(newProfile);
    }

    // ✅ Update profile for given student
    public Profile updateProfile(String studentName, Profile updatedProfile) {
        Student student = studentRepository.findByName(studentName)
                .orElseThrow(() -> new RuntimeException("Student not found: " + studentName));

        Profile existingProfile = profileRepository.findById(student.getId())
                .orElse(new Profile(student));

        // Link to student — REQUIRED for @MapsId
        existingProfile.setStudent(student);
        existingProfile.setStudentName(student.getName());

        // Update editable fields
        existingProfile.setDateOfBirth(updatedProfile.getDateOfBirth());
        existingProfile.setPhoneNumber(updatedProfile.getPhoneNumber());
        existingProfile.setStrengths(updatedProfile.getStrengths());
        existingProfile.setWeaknesses(updatedProfile.getWeaknesses());
        existingProfile.setInterests(updatedProfile.getInterests());
        existingProfile.setYearOfStudying(updatedProfile.getYearOfStudying());
        existingProfile.setCourse(updatedProfile.getCourse());

        return profileRepository.save(existingProfile);
    }
}