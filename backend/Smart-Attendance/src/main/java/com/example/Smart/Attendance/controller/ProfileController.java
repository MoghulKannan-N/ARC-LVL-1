package com.example.Smart.Attendance.controller;

import com.example.Smart.Attendance.model.Profile;
import com.example.Smart.Attendance.service.ProfileService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/profile")
@CrossOrigin(origins = "*") // Allow Flutter connection
public class ProfileController {

    @Autowired
    private ProfileService profileService;

    // 🔹 GET profile by name
    @GetMapping("/{studentName}")
    public Profile getProfile(@PathVariable String studentName) {
        return profileService.getProfileByName(studentName);
    }

    // 🔹 UPDATE profile
    @PutMapping("/{studentName}")
    public Profile updateProfile(@PathVariable String studentName, @RequestBody Profile updatedProfile) {
        return profileService.updateProfile(studentName, updatedProfile);
    }
}
