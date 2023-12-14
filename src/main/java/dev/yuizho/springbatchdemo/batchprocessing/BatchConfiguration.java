package dev.yuizho.springbatchdemo.batchprocessing;

import com.fasterxml.jackson.dataformat.csv.CsvMapper;
import io.awspring.cloud.s3.S3ObjectConverter;
import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.launch.support.RunIdIncrementer;
import org.springframework.batch.core.partition.support.Partitioner;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.batch.item.database.JdbcBatchItemWriter;
import org.springframework.batch.item.database.builder.JdbcBatchItemWriterBuilder;
import org.springframework.batch.item.file.FlatFileItemReader;
import org.springframework.batch.item.file.builder.FlatFileItemReaderBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ResourceLoader;
import org.springframework.core.task.TaskExecutor;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import javax.sql.DataSource;

@Configuration
public class BatchConfiguration {
    @Bean
    public FlatFileItemReader<Person> reader(ResourceLoader resourceLoader) {
        return new FlatFileItemReaderBuilder<Person>()
                .name("personItemReader")
                // https://www.baeldung.com/spring-cloud-aws-s3
                .resource(resourceLoader.getResource("s3://test-bucket/test-bucket/csv/sample-data.csv"))
                .delimited()
                .names("firstName", "lastName")
                .targetType(Person.class)
                .build();
    }

    @Bean
    public PersonItemProcessor processor() {
        return new PersonItemProcessor();
    }

    @Bean
    public JdbcBatchItemWriter<Person> writer(DataSource dataSource) {
        return new JdbcBatchItemWriterBuilder<Person>()
                .sql("INSERT INTO people (first_name, last_name) VALUES (:firstName, :lastName)")
                .dataSource(dataSource)
                .beanMapped()
                .build();
    }

    @Bean
    public Job importUserJob(JobRepository jobRepository, Step partitionStep, JobCompletionNotificationListener listener) {
        return new JobBuilder("importUserJob", jobRepository)
                .incrementer(new RunIdIncrementer())
                .listener(listener)
                .start(partitionStep)
                .build();
    }

    @Bean
    public TaskExecutor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(3);
        executor.setThreadNamePrefix("TaskExecutor-");
        executor.initialize();
        return executor;
    }

    @Bean
    public Partitioner stepPartitioner() {
        return new StepPertitioner();
    }

    @Bean
    public Step partitionStep(JobRepository jobRepository, DataSourceTransactionManager transactionManager,
                              FlatFileItemReader<Person> reader, PersonItemProcessor processor,
                              JdbcBatchItemWriter<Person> writer,
                              TaskExecutor taskExecutor,
                              Partitioner stepPertitioner) {
        // https://spring.pleiades.io/spring-batch/reference/scalability.html
        return new StepBuilder("partitionStep", jobRepository)
                .partitioner("slaveStep", stepPertitioner)
                .gridSize(3)
                .step(step1(jobRepository, transactionManager, reader, processor, writer))
                .taskExecutor(taskExecutor)
                .build();
    }

    @Bean
    public Step step1(JobRepository jobRepository, DataSourceTransactionManager transactionManager,
                      FlatFileItemReader<Person> reader, PersonItemProcessor processor, JdbcBatchItemWriter<Person> writer) {
        return new StepBuilder("step1", jobRepository)
                .<Person, Person> chunk(1, transactionManager)
                .reader(reader)
                .processor(processor)
                .writer(writer)
                .build();
    }

    @Bean
    public S3ObjectConverter s3ObjectConverter() {
        return new Jackson2CsvS3ObjectConverter(new CsvMapper());
    }
}
