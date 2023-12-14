package dev.yuizho.springbatchdemo.batchprocessing;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.dataformat.csv.CsvMapper;
import com.fasterxml.jackson.dataformat.csv.CsvSchema;
import io.awspring.cloud.s3.S3Exception;
import io.awspring.cloud.s3.S3ObjectConverter;
import org.springframework.util.Assert;
import software.amazon.awssdk.core.sync.RequestBody;

import java.io.IOException;
import java.io.InputStream;

public class Jackson2CsvS3ObjectConverter implements S3ObjectConverter {
    private final CsvMapper csvMapper;

    public Jackson2CsvS3ObjectConverter(CsvMapper csvMapper) {
        this.csvMapper = csvMapper;
    }

    @Override
    public <T> RequestBody write(T object) {
        Assert.notNull(object, "object is required");

        try {
            return RequestBody.fromBytes(csvMapper.writer(getCsvSchema(object.getClass())).writeValueAsBytes(object));
        }
        catch (JsonProcessingException e) {
            throw new S3Exception("Failed to serialize object to CSV", e);
        }
    }

    @Override
    public <T> T read(InputStream is, Class<T> clazz) {
        Assert.notNull(is, "InputStream is required");
        Assert.notNull(clazz, "Clazz is required");

        try {
            return csvMapper.reader(getCsvSchema(clazz)).readValue(is, clazz);
        }
        catch (IOException e) {
            throw new S3Exception("Failed to deserialize object from CSV", e);
        }

    }

    @Override
    public String contentType() {
        return "text/csv";
    }

    private <T> CsvSchema getCsvSchema(Class<T> clazz) {
        return csvMapper.schemaFor(clazz).withHeader();
    }
}
