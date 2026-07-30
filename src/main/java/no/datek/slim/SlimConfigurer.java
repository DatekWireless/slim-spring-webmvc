package no.datek.slim;

import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.beans.factory.support.BeanDefinitionRegistry;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.ViewResolver;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.view.InternalResourceViewResolver;
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

    /**
     * Drop Spring Boot's auto-registered {@code defaultViewResolver}. That
     * {@link InternalResourceViewResolver} resolves <em>any</em> view name to a servlet forward, so
     * a view name without a matching Slim template does not fail cleanly: it forwards to a path that
     * re-resolves to the same missing view and loops until the request thread dies with a
     * StackOverflowError. With the fallback gone, an unresolvable view name yields a plain
     * "Could not resolve view" error instead. Explicit {@code redirect:} / {@code forward:} views
     * are unaffected — the Slim resolver handles those prefixes itself.
     */
    @Bean
    static BeanFactoryPostProcessor removeForwardFallbackViewResolver() {
        return beanFactory -> {
            if (beanFactory instanceof BeanDefinitionRegistry registry
                    && registry.containsBeanDefinition("defaultViewResolver")
                    && beanFactory.getType("defaultViewResolver") == InternalResourceViewResolver.class) {
                registry.removeBeanDefinition("defaultViewResolver");
            }
        };
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
