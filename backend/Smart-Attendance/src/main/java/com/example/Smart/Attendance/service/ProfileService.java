package com.example.Smart.Attendance.service;

import com.example.Smart.Attendance.model.Profile;
import com.example.Smart.Attendance.model.Student;
import com.example.Smart.Attendance.repository.ProfileRepository;
import com.example.Smart.Attendance.repository.StudentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ProfileService {

    @Autowired
    private ProfileRepository profileRepository;

    @Autowired
    private StudentRepository studentRepository;

    // ✅ Get or create profile by student name
    public Profile getProfileByName(String studentName) {
        Student student = studentRepository.findByName(studentName)
                .orElseThrow(() -> new RuntimeException("Student not found: " + studentName));

        // Try to find an existing profile
        return profileRepository.findById(student.getId())
                .orElseGet(() -> {
                    // If not found, create a new linked profile
                    Profile newProfile = new Profile(student);
                    newProfile.setStudent(student);
                    newProfile.setName(student.getName());
                    return profileRepository.save(newProfile);
                });
    }

    // ✅ Update profile for given student
    public Profile updateProfile(String studentName, Profile updatedProfile) {
        Student student = studentRepository.findByName(studentName)
                .orElseThrow(() -> new RuntimeException("Student not found: " + studentName));

        Profile existingProfile = profileRepository.findById(student.getId())
                .orElse(new Profile(student));

        // Link to student — REQUIRED for @MapsId
        existingProfile.setStudent(student);
        existingProfile.setName(student.getName());

        // Update editable fields
        existingProfile.setDateOfBirth(updatedProfile.getDateOfBirth());
        existingProfile.setPhoneNumber(updatedProfile.getPhoneNumber());
        existingProfile.setStrength(updatedProfile.getStrength());
        existingProfile.setWeakness(updatedProfile.getWeakness());
        existingProfile.setInterest(updatedProfile.getInterest());
        existingProfile.setYearOfStudying(updatedProfile.getYearOfStudying());
        existingProfile.setCourse(updatedProfile.getCourse());

        return profileRepository.save(existingProfile);
    }
}
