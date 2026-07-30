package no.datek.slim;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.AutoConfigurations;
import org.springframework.boot.webmvc.autoconfigure.WebMvcAutoConfiguration;
import org.springframework.boot.test.context.runner.WebApplicationContextRunner;
import org.springframework.web.servlet.view.InternalResourceViewResolver;

/**
 * Regression guard for the missing-view forward loop. Spring Boot auto-registers a forward-based
 * {@code defaultViewResolver} that resolves <em>any</em> view name, so a view name with no matching
 * Slim template forwards to a path that re-resolves to the same missing view and loops until the
 * request thread dies with a {@code StackOverflowError}. {@link SlimConfigurer} must strip that
 * fallback so an unresolvable view name instead fails cleanly with "Could not resolve view".
 */
class SlimConfigurerTest {
    private final WebApplicationContextRunner runner = new WebApplicationContextRunner()
            .withConfiguration(AutoConfigurations.of(WebMvcAutoConfiguration.class));

    @Test
    void bootRegistersTheForwardFallbackByDefault() {
        // Guards the assumption the fix depends on: without SlimConfigurer the loop-causing
        // resolver is present. If Boot ever stops registering it, the removal below is moot.
        runner.run(context -> assertThat(context).hasSingleBean(InternalResourceViewResolver.class));
    }

    @Test
    void slimConfigurerRemovesTheForwardFallback() {
        runner.withUserConfiguration(SlimConfigurer.class).run(context -> {
            assertThat(context).doesNotHaveBean("defaultViewResolver");
            assertThat(context).doesNotHaveBean(InternalResourceViewResolver.class);
            // ...while keeping the Slim resolver, which declines a missing template instead of
            // forwarding to it.
            assertThat(context).hasBean("scriptTemplateViewResolver");
        });
    }
}
