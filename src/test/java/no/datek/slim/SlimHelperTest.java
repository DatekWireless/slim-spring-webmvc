package no.datek.slim;

import java.util.List;
import java.util.stream.Stream;
import org.jruby.embed.LocalContextScope;
import org.jruby.embed.ScriptingContainer;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

class SlimHelperTest {
    private static ScriptingContainer ruby;
    private static Object host;

    @BeforeAll
    static void loadSlimHelper() {
        ruby = new ScriptingContainer(LocalContextScope.SINGLETHREAD);
        ruby.setLoadPaths(List.of("uri:classloader:/ruby", "uri:classloader:/gems"));
        ruby.runScriptlet("""
                require 'slim_helper'

                class SlimHelperHost
                  include SlimHelper
                end
                """);
        host = ruby.runScriptlet("SlimHelperHost.new");
    }

    @AfterAll
    static void terminate() {
        ruby.terminate();
    }

    private static String markdown(String text) {
        return ruby.callMethod(host, "markdown", text, String.class).strip();
    }

    static Stream<Arguments> scriptInjections() {
        return Stream.of(
                Arguments.of("hi <script>alert(1)</script>", "<p>hi </p>"),
                Arguments.of("<img src=x onerror=\"alert(1)\">", "<p><img src=\"x\"></p>"),
                Arguments.of("[x](javascript:alert(1))", "<p><a>x</a></p>"),
                Arguments.of("[x](JaVaScRiPt:alert(1))", "<p><a>x</a></p>"),
                Arguments.of("[x](java&#x09;script:alert(1))", "<p><a>x</a></p>"),
                Arguments.of("[x](java\tscript:alert(1))", "<p><a>x</a></p>"),
                Arguments.of("<javascript:alert(1)>", "<p>&lt;javascript:alert(1)&gt;</p>"),
                Arguments.of("![x](data:image/svg+xml;base64,PHN2Zz48L3N2Zz4=)", "<p><img alt=\"x\"></p>"),
                // Kramdown inline attribute lists can put arbitrary attributes on generated elements.
                Arguments.of("para\n{: onclick=\"alert(1)\"}", "<p>para</p>"),
                Arguments.of("*x*{: onmouseover=\"alert(1)\"}", "<p><em>x</em></p>"),
                Arguments.of("<iframe src=\"https://evil.example\"></iframe>", ""),
                Arguments.of("<form action=\"https://evil.example\"><input name=p></form>", ""),
                Arguments.of("<style>body{display:none}</style>x", "<p>x</p>"));
    }

    @ParameterizedTest
    @MethodSource("scriptInjections")
    void markdownStripsScriptInjection(String text, String expectedHtml) {
        assertThat(markdown(text)).isEqualTo(expectedHtml);
    }

    @Test
    void markdownEscapesCodeBlockContent() {
        assertThat(markdown("~~~\n<script>alert(1)</script>\n~~~"))
                .isEqualTo("<pre><code>&lt;script&gt;alert(1)&lt;/script&gt;\n</code></pre>");
    }

    @Test
    void markdownKeepsSafeLinks() {
        assertThat(markdown("[a](/units/1) [b](#top) [c](https://example.com) <me@example.com>"))
                .contains("<a href=\"/units/1\">a</a>")
                .contains("<a href=\"#top\">b</a>")
                .contains("<a href=\"https://example.com\">c</a>")
                .contains("<a href=\"mailto:me@example.com\">me@example.com</a>");
    }

    @Test
    void markdownKeepsCommonFormatting() {
        assertThat(markdown("# Title\n\n**b** *i* `c`\n\n* item\n\n---\n\n| a |\n|---|\n| 1 |"))
                .contains("<h1>Title</h1>")
                .contains("<strong>b</strong> <em>i</em> <code>c</code>")
                .contains("<li>item</li>")
                .contains("<hr>")
                .contains("<td>1</td>");
    }

    @ParameterizedTest
    @ValueSource(strings = { "", "  \n " })
    void markdownOfBlankTextIsEmpty(String text) {
        assertThat(markdown(text)).isEmpty();
    }

    @Test
    void markdownOfNilIsEmpty() {
        assertThat(ruby.runScriptlet("SlimHelperHost.new.markdown(nil)")).hasToString("");
    }
}
