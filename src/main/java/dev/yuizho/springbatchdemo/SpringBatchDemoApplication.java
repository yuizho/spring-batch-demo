package dev.yuizho.springbatchdemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SpringBatchDemoApplication {

    public static void main(String[] args) {
        // job完了時にJVMは確実に終了する
        System.exit(
                SpringApplication.exit(
                        SpringApplication.run(SpringBatchDemoApplication.class, args)
                )
        );
    }

}
