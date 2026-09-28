package no.datek.slim;

import java.util.List;
import org.jruby.embed.LocalContextScope;
import org.jruby.embed.ScriptingContainer;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

class FormHelperTest {
    private static final String ESCAPED_PAYLOAD = "&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;";

    private static ScriptingContainer ruby;

    @BeforeAll
    static void loadFormHelper() {
        ruby = new ScriptingContainer(LocalContextScope.SINGLETHREAD);
        ruby.setLoadPaths(List.of("uri:classloader:/ruby"));
        ruby.runScriptlet("""
                require 'core_ext'
                require 'form_helper'

                PAYLOAD = %q{"><script>alert(1)</script>}

                class FormHelperHost
                  include FormHelper

                  def message = Hash.new('Label')
                end
                """);
    }

    @AfterAll
    static void terminate() {
        ruby.terminate();
    }

    private static String render(String helperCall) {
        return ruby.runScriptlet("FormHelperHost.new." + helperCall).toString();
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "text_input({ firstName: PAYLOAD }, :firstName)",
            "text_input(nil, :firstName, value: PAYLOAD)",
            "text_input(nil, :firstName, placeholder: PAYLOAD)",
            "text_input(nil, :firstName, title: PAYLOAD)",
            "bootstrap_text_field({ firstName: PAYLOAD }, :firstName)",
            "bootstrap_text_input(nil, :firstName, value: PAYLOAD)",
            "hidden_input({ id: PAYLOAD }, :id)",
            "hidden_field(nil, :id, value: PAYLOAD)",
            "date_input(nil, :day, value: PAYLOAD)",
            "bootstrap_date_input({ day: PAYLOAD }, :day)",
            "datetime_input({ from: PAYLOAD }, :from)",
            "textarea(nil, :comment, title: PAYLOAD)",
            "select_field(nil, :area, [[PAYLOAD, 'Label']])",
            "select_field(nil, :area, [], title: PAYLOAD)",
            "checkbox({ enabled: 'true' }, :enabled, value: PAYLOAD)",
            "custom_checkbox({ enabled: 'true' }, :enabled, value: PAYLOAD)",
    })
    void helpersEscapeInterpolatedValues(String helperCall) {
        String html = render(helperCall);

        assertThat(html).doesNotContain("<script>").contains(ESCAPED_PAYLOAD);
    }

    @Test
    void textareaEscapesContent() {
        String html = render("textarea({ comment: '</textarea><script>alert(1)</script>' }, :comment)");

        assertThat(html).doesNotContain("<script>").containsOnlyOnce("</textarea>")
                .contains("&lt;/textarea&gt;&lt;script&gt;alert(1)&lt;/script&gt;");
    }

    @Test
    void wrappingHelpersEscapeOnlyOnce() {
        assertThat(render("bootstrap_text_field({ name: 'Tom & Jerry' }, :name)"))
                .contains("value=\"Tom &amp; Jerry\"");
        assertThat(render("bootstrap_date_input({ day: 'a&b' }, :day)")).contains("value=\"a&amp;b\"");
        assertThat(render("bootstrap_textarea({ comment: 'a&b' }, :comment)")).contains(">a&amp;b</textarea>");
        assertThat(render("bootstrap_select(nil, :area, [['a&b', 'Label']])")).contains("value=\"a&amp;b\"");
        assertThat(render("bootstrap_checkbox({ enabled: 'true' }, :enabled, value: 'a&b')"))
                .contains("value=\"a&amp;b\"");
    }
}
