package no.datek.slim;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.ViewResolver;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.view.script.ScriptTemplateConfigurer;
import org.springframework.web.servlet.view.script.ScriptTemplateViewResolver;

@Configuration
public class SlimConfigurer implements WebMvcConfigurer {
    @Bean
    public ViewResolver scriptTemplateViewResolver() {
        ScriptTemplateViewResolver resolver = new ScriptTemplateViewResolver();
        resolver.setPrefix("/views/");
        resolver.setSuffix(".slim");
        return resolver;
    }

    @Bean
    public ScriptTemplateConfigurer jrubyConfigurer() {
        ScriptTemplateConfigurer configurer = new ScriptTemplateConfigurer();
        configurer.setEngineName("jruby");
        configurer.setScripts("ruby/load_slim.rb");
        configurer.setRenderObject("SlimRenderer");
        configurer.setRenderFunction("render");
        return configurer;
    }
}
