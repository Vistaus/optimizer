/* SystemCleanerView.vala
 *
 * Copyright 2019 Hannes Schulze
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Optimizer.Configs;
using Optimizer.Widgets;

namespace Optimizer.Views {

    /**
     * The {@code SystemCleanerView} class.
     *
     * @since 1.0.0
     */
    public class SystemCleanerView : Gtk.Overlay {
        private Gtk.Grid              main_grid;
        private Granite.Widgets.Toast error_toast;
        private Granite.Widgets.Toast calculating_toast;
        private Granite.Widgets.Toast status_toast;
        private Granite.Widgets.Toast result_toast;
        private Gtk.Box               toast_box;
        private Gtk.CheckButton       trash_checkbox;
        private Gtk.CheckButton       application_caches_checkbox;
        private Gtk.CheckButton       application_logs_checkbox;
        private Gtk.CheckButton       crash_reports_checkbox;
        private Gtk.CheckButton       package_caches_checkbox;
        private string[]?             package_cache_location;
        private Gtk.CheckButton       select_all_btn;
        private Gtk.Button            clean_up_button;
        private bool[]                last_toggled;

        /**
         * Constructs a new {@code SystemCleanerView} object.
         */
        public SystemCleanerView () {
            last_toggled = { false, false, false, false, false };

            error_toast = new Granite.Widgets.Toast ("");
            calculating_toast = new Granite.Widgets.Toast ("");
            status_toast = new Granite.Widgets.Toast ("");
            result_toast = new Granite.Widgets.Toast ("");
            toast_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            toast_box.pack_start (error_toast, false, false, 0);
            toast_box.pack_start (calculating_toast, false, false, 0);
            toast_box.pack_start (status_toast, false, false, 0);
            toast_box.pack_start (result_toast, false, false, 0);
            toast_box.valign = Gtk.Align.START;
            add_overlay (toast_box);

            main_grid = new Gtk.Grid ();
            main_grid.halign = Gtk.Align.CENTER;
            main_grid.valign = Gtk.Align.CENTER;
            main_grid.column_homogeneous = true;
            main_grid.column_spacing = 36;
            main_grid.row_spacing = 12;
            main_grid.expand = true;
            add (main_grid);

            // Package Caches
            package_cache_location = get_package_manager_cache ();
            if (package_cache_location != null) {
                var package_caches_icon = new Gtk.Image ();
                package_caches_icon.gicon = new ThemedIcon ("package-x-generic");
                package_caches_icon.pixel_size = 64;
                main_grid.attach (package_caches_icon, 0, 0, 1, 1);

                var package_caches_label = new Gtk.Label (_("Package Caches"));
                package_caches_label.halign = Gtk.Align.CENTER;
                main_grid.attach (package_caches_label, 0, 1, 1, 1);

                package_caches_checkbox = new Gtk.CheckButton ();
                package_caches_checkbox.halign = Gtk.Align.CENTER;
                main_grid.attach (package_caches_checkbox, 0, 2, 1, 1);
            } else {
                stderr.printf ("WARNING: Deleting package caches is not supported on this platform.\n");
            }

            // Crash Reports
            var crash_reports_icon = new Gtk.Image ();
            crash_reports_icon.gicon = new ThemedIcon ("dialog-error");
            crash_reports_icon.pixel_size = 64;
            if (package_cache_location != null) {
                main_grid.attach (crash_reports_icon, 1, 0, 1, 1);
            } else {
                main_grid.attach (crash_reports_icon, 0, 0, 1, 1);
            }

            var crash_reports_label = new Gtk.Label (_("Crash Reports"));
            crash_reports_label.halign = Gtk.Align.CENTER;
            main_grid.attach_next_to (crash_reports_label, crash_reports_icon, Gtk.PositionType.BOTTOM);

            crash_reports_checkbox = new Gtk.CheckButton ();
            crash_reports_checkbox.halign = Gtk.Align.CENTER;
            main_grid.attach_next_to (crash_reports_checkbox, crash_reports_label, Gtk.PositionType.BOTTOM);

            // Application Logs
            var application_logs_icon = new Gtk.Image ();
            application_logs_icon.gicon = new ThemedIcon ("text-x-generic");
            application_logs_icon.pixel_size = 64;
            main_grid.attach_next_to (application_logs_icon, crash_reports_icon, Gtk.PositionType.RIGHT);

            var application_logs_label = new Gtk.Label (_("Application Logs"));
            application_logs_label.halign = Gtk.Align.CENTER;
            main_grid.attach_next_to (application_logs_label, application_logs_icon, Gtk.PositionType.BOTTOM);

            application_logs_checkbox = new Gtk.CheckButton ();
            application_logs_checkbox.halign = Gtk.Align.CENTER;
            main_grid.attach_next_to (application_logs_checkbox, application_logs_label, Gtk.PositionType.BOTTOM);

            // Application Caches
            var application_caches_icon = new Gtk.Image ();
            application_caches_icon.gicon = new ThemedIcon ("application-x-executable");
            application_caches_icon.pixel_size = 64;
            main_grid.attach_next_to (application_caches_icon, application_logs_icon, Gtk.PositionType.RIGHT);

            var application_caches_label = new Gtk.Label (_("Application Caches"));
            application_caches_label.halign = Gtk.Align.CENTER;
            main_grid.attach_next_to (application_caches_label, application_caches_icon, Gtk.PositionType.BOTTOM);

            application_caches_checkbox = new Gtk.CheckButton ();
            application_caches_checkbox.halign = Gtk.Align.CENTER;
            main_grid.attach_next_to (application_caches_checkbox, application_caches_label, Gtk.PositionType.BOTTOM);

            // Trash
            var trash_icon = new Gtk.Image ();
            trash_icon.gicon = new ThemedIcon ("user-trash-full");
            trash_icon.pixel_size = 64;
            main_grid.attach_next_to (trash_icon, application_caches_icon, Gtk.PositionType.RIGHT);

            var trash_label = new Gtk.Label (_("Trash"));
            trash_label.halign = Gtk.Align.CENTER;
            main_grid.attach_next_to (trash_label, trash_icon, Gtk.PositionType.BOTTOM);

            trash_checkbox = new Gtk.CheckButton ();
            trash_checkbox.halign = Gtk.Align.CENTER;
            main_grid.attach_next_to (trash_checkbox, trash_label, Gtk.PositionType.BOTTOM);

            var clean_up_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 24);
            clean_up_box.halign = Gtk.Align.CENTER;
            clean_up_box.margin_top = 24;

            // Select all checkbox
            select_all_btn = new Gtk.CheckButton.with_label (_("Select all"));
            select_all_btn.valign = Gtk.Align.CENTER;
            select_all_btn.toggled.connect (select_all);
            clean_up_box.pack_start (select_all_btn, false, true);

            // Clean Up button
            clean_up_button = new Gtk.Button.with_label (_("Clean Up"));
            clean_up_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            clean_up_button.valign = Gtk.Align.CENTER;
            clean_up_button.clicked.connect (clean_up);
            clean_up_box.pack_start (clean_up_button, false, true);

            if (package_cache_location != null) {
                main_grid.attach (clean_up_box, 0, 3, 5, 1);
            } else {
                main_grid.attach (clean_up_box, 0, 3, 4, 1);
            }
        }

        private void select_all () {
            if (select_all_btn.active) {
                last_toggled[0] = trash_checkbox.active;
                last_toggled[1] = application_caches_checkbox.active;
                last_toggled[2] = application_logs_checkbox.active;
                last_toggled[3] = crash_reports_checkbox.active;
                last_toggled[4] = package_caches_checkbox.active;
                trash_checkbox.active = true;
                application_caches_checkbox.active = true;
                application_logs_checkbox.active = true;
                crash_reports_checkbox.active = true;
                package_caches_checkbox.active = true;
            } else {
                trash_checkbox.active = last_toggled[0];
                application_caches_checkbox.active = last_toggled[1];
                application_logs_checkbox.active = last_toggled[2];
                crash_reports_checkbox.active = last_toggled[3];
                package_caches_checkbox.active = last_toggled[4];
            }
        }

        private void clean_up () {
            var selected_folders = new Gee.HashMap<string, string> ();
            bool needs_root = false;

            if (package_caches_checkbox.active) {
                needs_root = true;
                selected_folders[package_cache_location[0]] = package_cache_location[1];
            }
            if (crash_reports_checkbox.active) {
                needs_root = true;
                selected_folders["/var/crash"] = "crash";
            }
            if (application_logs_checkbox.active) {
                needs_root = true;
                selected_folders["/var/log"] = "";
            }
            if (application_caches_checkbox.active) {
                selected_folders[Path.build_filename (Environment.get_home_dir (), ".cache")] = "";
            }
            if (trash_checkbox.active) {
                selected_folders[Path.build_filename (Environment.get_home_dir (), ".local/share/Trash/files")] = "";
                selected_folders[Path.build_filename (Environment.get_home_dir (), ".local/share/Trash/info")] = "trashinfo";
            }

            if (!selected_folders.is_empty) {
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Do you want to continue?"),
                    "",
                    "dialog-warning",
                    Gtk.ButtonsType.CANCEL);
                message_dialog.width_request = 600;

                var continue_button = new Gtk.Button.with_label (_("Continue"));
                continue_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                message_dialog.add_action_widget (continue_button, Gtk.ResponseType.ACCEPT);


                calculating_toast.title = _("Calculating file size…");
                clean_up_button.sensitive = false;
                calculating_toast.send_notification ();
                Utils.DiskSpace.get_formatted_file_list.begin (selected_folders, (obj, res) => {
                    var files_list_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                    files_list_box.width_request = 300;

                    uint64 total_file_size = 0;
                    Utils.DiskSpace.FormattedList[] folder_list = Utils.DiskSpace.get_formatted_file_list.end (res);

                    foreach (var folder in folder_list) {
                        var scrolled_window = new Gtk.ScrolledWindow (null, null);
                        var list_view = new Gtk.TextView ();
                        list_view.border_width = 6;
                        list_view.editable = false;
                        list_view.wrap_mode = Gtk.WrapMode.WORD;
                        total_file_size += folder.folder_size;
                        list_view.buffer.text = folder.file_list;
                        scrolled_window.add (list_view);
                        scrolled_window.height_request = 150;

                        var expander = new Gtk.Expander (folder.heading);
                        expander.add (scrolled_window);
                        files_list_box.pack_start (expander);
                    }

                    message_dialog.secondary_text = _("This will delete the following files (%s):").printf
                        (GLib.format_size (total_file_size, FormatSizeFlags.IEC_UNITS));
                    message_dialog.custom_bin.add (files_list_box);

                    message_dialog.show_all ();
                    if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                        status_toast.title = _("Deleting selected files…");
                        status_toast.send_notification ();

                        string[] folder_names = { };
                        foreach (var folder in selected_folders.entries) {
                            var extension = "*";
                            if (folder.value != "") {
                                extension += "." + folder.value;
                            }
                            folder_names += Path.build_filename (folder.key, extension);
                        }
                        remove_files (folder_names, needs_root);
                    } else {
                        clean_up_button.sensitive = true;
                    }
                    message_dialog.destroy ();
                });
            } else {
                error_toast.title = _("No items selected");
                error_toast.send_notification ();
            }
        }

        private void remove_files (string[] files, bool needs_root) {
            string[] spawn_args = {};
            if (needs_root) {
                spawn_args += "pkexec";
            }
            spawn_args += "sh";
            spawn_args += "-c";

            string[] new_files = { };
            foreach (var file in files) {
                if (!check_empty (file)) {
                    new_files += file;
                }
            }
            if (new_files.length == 0) {
                result_toast.title = _("Finished cleaning up with no errors");
	            result_toast.send_notification ();
                return;
            }
            spawn_args += "rm -r " + string.joinv (" ", new_files);

            string[] spawn_env = Environ.get ();
            Pid child_pid;

            try {
                int standard_input;
		        int standard_output;
		        int standard_error;

		        Process.spawn_async_with_pipes ("/",
			        spawn_args,
			        spawn_env,
			        SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
			        null,
			        out child_pid,
			        out standard_input,
			        out standard_output,
			        out standard_error);

		        // stderr:
		        IOChannel error = new IOChannel.unix_new (standard_error);
		        bool got_error = false;
		        error.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
		            if (condition == IOCondition.HUP) {
		                return false;
	                }

	                try {
		                string line;
		                channel.read_line (out line, null, null);
		                print ("Output on stderr while trying to delete files: %s", line);
		                got_error = true;
	                } catch (Error e) {
		                return false;
	                }

			        return true;
		        });

                ChildWatch.add (child_pid, (pid, status) => {
	                Process.close_pid (pid);
	                result_toast.title = _("Finished cleaning up %s").printf
	                    (got_error ? _("with errors!") : _("with no errors"));
	                result_toast.send_notification ();
                    clean_up_button.sensitive = true;
                });
            } catch (SpawnError err) {
                stderr.printf ("Could not spawn command: %s\n", err.message);
            }
        }

        private bool check_empty (string path) {
            string[] spawn_args = { "sh", "-c", "ls %s".printf (path) };
            string[] spawn_env = Environ.get ();
            string ls_stdout;

            try {
                Process.spawn_sync ("/", spawn_args, spawn_env,
                    SpawnFlags.SEARCH_PATH | SpawnFlags.STDERR_TO_DEV_NULL,
                    null, out ls_stdout);

                if (ls_stdout.length > 0) {
                    return false;
                }
                return true;
            } catch (SpawnError err) {
                stderr.printf ("Spawn error: %s\n", err.message);
                return true;
            }
        }

        private string[]? get_package_manager_cache () {
            if (Environment.find_program_in_path ("apt-get") != null) {
                return { "/var/cache/apt/archives", "deb" };
            }
            if (Environment.find_program_in_path ("pacman") != null) {
                return { "/var/cache/pacman/pkg", "xz" };
            }

            return null;
        }
    }
}
