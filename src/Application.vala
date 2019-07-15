/*-
 * Copyright (c) 2011-2015 Eidete Developers
 * Copyright (c) 2017-2018 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace Screencast {
    public class ScreencastApp : Granite.Application {
        static ScreencastApp _instance = null;

        public static ScreencastApp instance {
            get {
                if (_instance == null)
                    _instance = new ScreencastApp ();
                return _instance;
            }
        }

        construct {
            this.flags |= ApplicationFlags.HANDLES_COMMAND_LINE;

            program_name = "Screencast";
            exec_name = "com.github.artemanufrij.screencast";
            application_id = exec_name;
            app_launcher = exec_name + ".desktop";
        }

        public MainWindow mainwindow { get; private set; default = null; }

        protected override void activate () {
            if (mainwindow != null) {
                if (mainwindow.recording) {
                    mainwindow.pause_recording ();
                }
                mainwindow.present ();
                return;
            }

            var settings  = Settings.get_default ();

            File screecast_folder = File.new_for_path (settings.save_folder);
            if (settings.save_folder == "" || !screecast_folder.query_exists ()) {
                settings.save_folder = Environment.get_user_special_dir (UserDirectory.VIDEOS);
            }

            mainwindow = new MainWindow ();
            mainwindow.application = this;

            Interfaces.MediaKeyListener.listen ();
        }

        public override int command_line (ApplicationCommandLine cmd) {
            string[] args_cmd = cmd.get_arguments ();
            unowned string[] args = args_cmd;

            bool toggle = false;
            bool finish = false;

            GLib.OptionEntry [] options = new OptionEntry [3];
            options [0] = { "toggle", 0, 0, OptionArg.NONE, ref toggle, (_("Toggle recording")), null };
            options [1] = { "finish", 0, 0, OptionArg.NONE, ref finish, (_("Finish recording")), null };
            options [2] = { null };

            var opt_context = new OptionContext ("actions");
            opt_context.set_help_enabled (true);
            opt_context.add_main_entries (options, null);
            try {
                opt_context.parse (ref args);
            } catch (Error err) {
                warning (err.message);
                return 0;
            }

            if (toggle) {
                if (mainwindow == null) {
                    activate ();
                }
                mainwindow.toggle_recording ();
            } else if (finish) {
                mainwindow.stop_recording ();
            }

            if (!toggle) {
                activate ();
            }

            return 0;
        }
    }
}


public static int main (string [] args) {
    Gst.init (ref args);
    var app = Screencast.ScreencastApp.instance;
    return app.run (args);
}
