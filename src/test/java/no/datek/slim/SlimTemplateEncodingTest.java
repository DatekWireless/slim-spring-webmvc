package no.datek.slim;

import java.util.List;
import org.jruby.embed.LocalContextScope;
import org.jruby.embed.ScriptingContainer;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Tilt compiles a template on its first render without a lock and briefly switches the shared source to BINARY while it
 * looks for a magic comment. Concurrent first renders could then compile non-ASCII literals as ASCII-8BIT and cache the
 * broken template. slim_renderer.rb passes skip_compiled_encoding_detection to avoid that.
 */
class SlimTemplateEncodingTest {
    private static ScriptingContainer ruby;

    @BeforeAll
    static void loadSlim() {
        ruby = new ScriptingContainer(LocalContextScope.SINGLETHREAD);
        ruby.setLoadPaths(List.of("uri:classloader:/ruby", "uri:classloader:/gems"));
        ruby.runScriptlet("""
                require 'slim'
                
                def concurrent_first_render_failures(rounds, threads, options)
                  source = "div data-subtitle=\\"a · b\\" = title\\n"
                  rounds.times.count do
                    template = Slim::Template.new('race.slim', options) { source }
                    start = Queue.new
                    workers = Array.new(threads) do
                      Thread.new do
                        start.pop
                        template.render(Object.new, title: 'æøå')
                        nil
                      rescue Encoding::CompatibilityError => e
                        e
                      end
                    end
                    threads.times { start << true }
                    workers.map(&:value).any?
                  end
                end
                """);
    }

    @AfterAll
    static void terminate() {
        ruby.terminate();
    }

    @Test
    void concurrentFirstRendersKeepUtf8Literals() {
        Object failures =
                ruby.runScriptlet("concurrent_first_render_failures(500, 8, skip_compiled_encoding_detection: true)");
        assertThat(((Number) failures).intValue()).isZero();
    }
}
