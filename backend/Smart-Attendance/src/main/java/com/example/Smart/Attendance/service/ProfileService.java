package com.example.Smart.Attendance.service;

import com.example.Smart.Attendance.model.Profile;
import com.example.Smart.Attendance.repository.ProfileRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class ProfileService {

    @Autowired
    private ProfileRepository profileRepository;

    public Profile getProfileByName(String studentName) {
        return profileRepository.findByStudentName(studentName);
    }

    public Profile updateProfile(String studentName, Profile updatedProfile) {
        Profile existingProfile = profileRepository.findByStudentName(studentName);
        if (existingProfile == null) {
            // create a new one if not found
            return profileRepository.save(updatedProfile);
        }

        // Update fields
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
