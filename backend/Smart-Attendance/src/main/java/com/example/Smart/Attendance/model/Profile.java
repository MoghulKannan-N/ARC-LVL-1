package com.example.Smart.Attendance.model;

import jakarta.persistence.*;

@Entity
@Table(name = "student_profiles")
public class Profile {

    @Id
    private Long id; // same as Student.id — shared primary key

    @Column(nullable = false)
    private String name; // same as Student.name

    private String dateOfBirth;
    private String phoneNumber;
    private String strength;
    private String weakness;
    private String interest;
    private String yearOfStudying;
    private String course;

    // One-to-one mapping with Student entity
    @OneToOne
    @MapsId
    @JoinColumn(name = "id") // links to Student.id
    private Student student;

    public Profile() {}

    public Profile(Student student) {
        this.student = student;
        this.name = student.getName();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDateOfBirth() {
        return dateOfBirth;
    }

    public void setDateOfBirth(String dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getStrength() {
        return strength;
    }

    public void setStrength(String strength) {
        this.strength = strength;
    }

    public String getWeakness() {
        return weakness;
    }

    public void setWeakness(String weakness) {
        this.weakness = weakness;
    }

    public String getInterest() {
        return interest;
    }

    public void setInterest(String interest) {
        this.interest = interest;
    }

    public String getYearOfStudying() {
        return yearOfStudying;
    }

    public void setYearOfStudying(String yearOfStudying) {
        this.yearOfStudying = yearOfStudying;
    }

    public String getCourse() {
        return course;
    }

    public void setCourse(String course) {
        this.course = course;
    }

    public Student getStudent() {
        return student;
    }

    public void setStudent(Student student) {
        this.student = student;
        this.name = student.getName(); // keep names synced
    }
}
