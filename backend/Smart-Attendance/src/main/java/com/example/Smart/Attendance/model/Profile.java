package com.example.Smart.Attendance.model;

import jakarta.persistence.*;

@Entity
@Table(name = "student_profiles")
public class Profile {

    @Id
    private Long id; // same as Student.id — shared primary key

    @Column(name = "student_name", nullable = false)
    private String studentName; // mapped to DB column student_name

    private String dateOfBirth;
    private String phoneNumber;

    @Column(name = "strengths")
    private String strengths; // renamed column

    @Column(name = "weaknesses")
    private String weaknesses; // renamed column

    @Column(name = "interests")
    private String interests; // renamed column

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
        this.studentName = student != null ? student.getName() : null;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getStudentName() {
        return studentName;
    }

    public void setStudentName(String studentName) {
        this.studentName = studentName;
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

    public String getStrengths() {
        return strengths;
    }

    public void setStrengths(String strengths) {
        this.strengths = strengths;
    }

    public String getWeaknesses() {
        return weaknesses;
    }

    public void setWeaknesses(String weaknesses) {
        this.weaknesses = weaknesses;
    }

    public String getInterests() {
        return interests;
    }

    public void setInterests(String interests) {
        this.interests = interests;
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
        this.studentName = student != null ? student.getName() : this.studentName; // keep names synced
}
}
