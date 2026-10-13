namespace AppManager.Core {
    // Identity grants require a matched component, unlike display-only metadata.
    public class AppStreamIdentity {
        private string? id;
        private string? name;
        private Gee.ArrayList<string> launchables = new Gee.ArrayList<string>();
        private Gee.ArrayList<string> elements = new Gee.ArrayList<string>();
        private StringBuilder text = new StringBuilder();
        private string? launchable_type;
        private bool localized;
        private int best_score;
        private string? best_id;
        private bool ambiguous;
        private string desktop;
        private string app_name;

        public AppStreamIdentity(string desktop, string? app_name) {
            this.desktop = Path.get_basename(desktop);
            this.app_name = app_name ?? "";
        }

        public void add_xml(string xml) {
            MarkupParser parser = { start_element, end_element, text_content, null, null };
            // Parse into a temporary selector: malformed XML must grant nothing.
            var parsed = new AppStreamIdentity(desktop, app_name);
            var context = new MarkupParseContext(parser, MarkupParseFlags.TREAT_CDATA_AS_TEXT, parsed, null);
            try {
                context.parse(xml, xml.length);
                context.end_parse();
                if (parsed.best_score > best_score) {
                    best_score = parsed.best_score;
                    best_id = parsed.best_id;
                    ambiguous = parsed.ambiguous;
                } else if (parsed.best_score > 0 && parsed.best_score == best_score) {
                    ambiguous = ambiguous || parsed.ambiguous || best_id != parsed.best_id;
                }
            } catch (MarkupError e) {
                debug("Ignoring invalid AppStream identity XML: %s", e.message);
            }
        }

        public string? matched_id() {
            return ambiguous ? null : best_id;
        }

        private static void start_element(MarkupParseContext context, string element,
                                          string[] attribute_names, string[] attribute_values) throws MarkupError {
            var self = (AppStreamIdentity) context.get_user_data();
            self.elements.add(element);
            self.text.truncate(0);
            self.localized = false;
            self.launchable_type = null;
            for (int i = 0; i < attribute_names.length; i++) {
                if (attribute_names[i] == "xml:lang") self.localized = true;
                if (attribute_names[i] == "type") self.launchable_type = attribute_values[i];
            }
            if (element == "component" || element == "application") {
                self.id = null;
                self.name = null;
                self.launchables.clear();
            }
        }

        private static void text_content(MarkupParseContext context, string content, size_t length) throws MarkupError {
            var self = (AppStreamIdentity) context.get_user_data();
            self.text.append_len(content, (ssize_t) length);
        }

        private static void end_element(MarkupParseContext context, string element) throws MarkupError {
            var self = (AppStreamIdentity) context.get_user_data();
            int n = self.elements.size;
            bool direct = n >= 2 && (self.elements[n - 2] == "component" || self.elements[n - 2] == "application");
            var value = self.text.str.strip();
            if (direct && element == "id") self.id = value;
            if (direct && element == "name" && !self.localized) self.name = value;
            if (direct && element == "launchable" && self.launchable_type == "desktop-id") {
                self.launchables.add(value);
            }
            if (element == "component" || element == "application") self.select_component();
            self.elements.remove_at(n - 1);
            self.text.truncate(0);
        }

        private static string stem(string id) {
            return id.has_suffix(".desktop") ? id.substring(0, id.length - 8) : id;
        }

        private void select_component() {
            if (id == null || id == "") return;
            int score = 0;
            if (launchables.contains(desktop)) score = 100;
            else if (stem(id) == stem(desktop)) score = 80;
            // A declared different desktop launchable overrides a coincidental name.
            else if (launchables.size == 0 && app_name != "" && name == app_name) score = 60;
            if (score > best_score) {
                best_score = score;
                best_id = id;
                ambiguous = false;
            } else if (score > 0 && score == best_score && best_id != id) {
                ambiguous = true;
            }
        }

        public void add_directory(string path, int depth = 6) {
            if (depth <= 0) return;
            try {
                var files = File.new_for_path(path).enumerate_children(
                    "standard::name,standard::type", FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                FileInfo? info;
                while ((info = files.next_file()) != null) {
                    var child = files.get_child(info).get_path();
                    if (info.get_file_type() == FileType.DIRECTORY) add_directory(child, depth - 1);
                    else if (info.get_file_type() == FileType.REGULAR && info.get_name().has_suffix(".xml")) {
                        string xml;
                        GLib.FileUtils.get_contents(child, out xml);
                        add_xml(xml);
                    }
                }
            } catch (Error e) {
                debug("Could not read AppStream identities in %s: %s", path, e.message);
            }
        }
    }
}
