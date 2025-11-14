package com.benchmark.springcrud.repository;

import com.benchmark.springcrud.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StudentRepository extends JpaRepository<Student, Long> {
}
