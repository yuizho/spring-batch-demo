package dev.yuizho.springbatchdemo.batchprocessing;

import com.fasterxml.jackson.dataformat.csv.CsvMapper;
import io.awspring.cloud.s3.S3ObjectConverter;
import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.launch.support.RunIdIncrementer;
import org.springframework.batch.core.partition.support.Partitioner;
import org.springframework.batch.core.partition.support.SimplePartitioner;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.batch.item.database.JdbcBatchItemWriter;
import org.springframework.batch.item.database.builder.JdbcBatchItemWriterBuilder;
import org.springframework.batch.item.file.FlatFileItemReader;
import org.springframework.batch.item.file.builder.FlatFileItemReaderBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
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
                //.resource(resourceLoader.getResource("s3://test-bucket/test-bucket/csv/sample-data.csv"))
                .resource(new ClassPathResource("sample-data.csv"))
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
        executor.setCorePoolSize(4);
        executor.setThreadNamePrefix("TaskExecutor-");
        executor.initialize();
        return executor;
    }

    @Bean
    public Partitioner partitioner() {
        return new SimplePartitioner();
    }

    @Bean
    public Step partitionStep(JobRepository jobRepository, DataSourceTransactionManager transactionManager,
                              FlatFileItemReader<Person> reader, PersonItemProcessor processor,
                              JdbcBatchItemWriter<Person> writer,
                              TaskExecutor taskExecutor,
                              Partitioner partitioner) {
        // https://spring.pleiades.io/spring-batch/reference/scalability.html
        return new StepBuilder("partitionStep", jobRepository)
                .partitioner("slaveStep", partitioner)
                // https://spring.pleiades.io/spring-batch/reference/scalability.html#:~:text=gridSize%C2%A0%E5%B1%9E%E6%80%A7%E3%81%AF%E3%80%81%E4%BD%9C%E6%88%90%E3%81%99%E3%82%8B%E5%80%8B%E5%88%A5%E3%81%AE%E3%82%B9%E3%83%86%E3%83%83%E3%83%97%E5%AE%9F%E8%A1%8C%E3%81%AE%E6%95%B0%E3%82%92%E6%B1%BA%E5%AE%9A%E3%81%99%E3%82%8B%E3%81%9F%E3%82%81%E3%80%81TaskExecutor%20%E3%81%AE%E3%82%B9%E3%83%AC%E3%83%83%E3%83%89%E3%83%97%E3%83%BC%E3%83%AB%E3%81%AE%E3%82%B5%E3%82%A4%E3%82%BA%E3%81%A8%E4%B8%80%E8%87%B4%E3%81%95%E3%81%9B%E3%82%8B%E3%81%93%E3%81%A8%E3%81%8C%E3%81%A7%E3%81%8D%E3%81%BE%E3%81%99%E3%80%82%E3%81%BE%E3%81%9F%E3%81%AF%E3%80%81%E4%BD%BF%E7%94%A8%E5%8F%AF%E8%83%BD%E3%81%AA%E3%82%B9%E3%83%AC%E3%83%83%E3%83%89%E3%81%AE%E6%95%B0%E3%82%88%E3%82%8A%E3%82%82%E5%A4%A7%E3%81%8D%E3%81%8F%E8%A8%AD%E5%AE%9A%E3%81%97%E3%81%A6%E3%80%81%E4%BD%9C%E6%A5%AD%E3%83%96%E3%83%AD%E3%83%83%E3%82%AF%E3%82%92%E5%B0%8F%E3%81%95%E3%81%8F%E3%81%99%E3%82%8B%E3%81%93%E3%81%A8%E3%82%82%E3%81%A7%E3%81%8D%E3%81%BE%E3%81%99%E3%80%82
                .gridSize(4)
                .step(step1(jobRepository, transactionManager, reader, processor, writer))
                .taskExecutor(taskExecutor)
                .build();
    }

    @Bean
    public Step step1(JobRepository jobRepository, DataSourceTransactionManager transactionManager,
                      FlatFileItemReader<Person> reader, PersonItemProcessor processor, JdbcBatchItemWriter<Person> writer) {
        return new StepBuilder("step1", jobRepository)
                // chunkSize数にチャンクを分けて、分けたチャンクの単位でコミットする
                // 大量に処理する場合は、それなりに大きい値を指定したほうが処理効率は良い
                .<Person, Person> chunk(10, transactionManager)
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
