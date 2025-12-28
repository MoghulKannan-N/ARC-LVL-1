package com.example.Smart.Attendance.model;

import jakarta.persistence.*;

@Entity
@Table(name = "student")
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String username;
    private String password;

    private Long teacherId;

    // ---------- NEW FIELDS (Required for AI + Profile Screen) ----------
    private String dateOfBirth;
    private String phoneNumber;

    private String strength;
    private String weakness;
    private String interest;

    private String yearOfStudying;
    private String course;

    public Student() {}

    public Student(String name, String username, String password, Long teacherId) {
        this.name = name;
        this.username = username;
        this.password = password;
        this.teacherId = teacherId;
    }

    // ---------------------- GETTERS / SETTERS ------------------------

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public Long getTeacherId() { return teacherId; }
    public void setTeacherId(Long teacherId) { this.teacherId = teacherId; }

    public String getDateOfBirth() { return dateOfBirth; }
    public void setDateOfBirth(String dateOfBirth) { this.dateOfBirth = dateOfBirth; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public String getStrength() { return strength; }
    public void setStrength(String strength) { this.strength = strength; }

    public String getWeakness() { return weakness; }
    public void setWeakness(String weakness) { this.weakness = weakness; }

    public String getInterest() { return interest; }
    public void setInterest(String interest) { this.interest = interest; }

    public String getYearOfStudying() { return yearOfStudying; }
    public void setYearOfStudying(String yearOfStudying) { this.yearOfStudying = yearOfStudying; }

    public String getCourse() { return course; }
    public void setCourse(String course) { this.course = course; }
}
