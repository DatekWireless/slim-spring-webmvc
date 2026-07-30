package no.datek.slim;

import jakarta.servlet.http.HttpServletRequest;
import java.nio.file.Path;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.NoHandlerFoundException;

@Controller
@RequestMapping(AssetsController.PAGE_PATH)
public class AssetsController {
    public static final String PAGE_PATH = "/assets";

    @GetMapping("**")
    @ResponseBody
    public HttpEntity<FileSystemResource> show(HttpServletRequest request) throws NoHandlerFoundException {
        String hashedPath = request.getServletPath().replace(PAGE_PATH, "");
        FileSystemResource fileSystemResource = new FileSystemResource(AssetStore.getFile(hashedPath));
        if (!fileSystemResource.isReadable()) {
            throw new NoHandlerFoundException(request.getMethod(), request.getRequestURI(), new HttpHeaders());
        }
        HttpHeaders headers = new HttpHeaders();
        if (hashedPath.endsWith(".css")) {
            headers.setContentType(MediaType.parseMediaType("text/css;charset=UTF-8"));
        } else {
            headers.setContentType(MediaType.parseMediaType("text/javascript;charset=UTF-8"));
        }
        headers.setCacheControl("public, max-age=31536000");
        headers.setContentDisposition(
                ContentDisposition.parse("inline; filename=" + Path.of(hashedPath).getFileName()));
        return new ResponseEntity<>(fileSystemResource, headers, HttpStatus.OK);
    }
}
