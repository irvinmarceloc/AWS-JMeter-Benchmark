package com.benchmark.springcrud.repository;

import com.benchmark.springcrud.entity.Course;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CourseRepository extends JpaRepository<Course, Long> {
}
