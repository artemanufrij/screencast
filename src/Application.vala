/*-
 * Copyright (c) 2011-2015 Eidete Developers
 * Copyright (c) 2017-2017 Artem Anufrij <artem.anufrij@live.de>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
            program_name = "Screencast";
            exec_name = "com.github.artemanufrij.screencast";
            application_id = exec_name;
            app_launcher = exec_name + ".desktop";
        }

        public MainWindow mainwindow { get; set; }

        protected override void activate () {
            if (mainwindow != null) {
                mainwindow.present ();
                return;
            }

            var settings  = Settings.get_default ();

            File screecast_folder = File.new_for_path (settings.save_folder);
            if (settings.save_folder == "" || !screecast_folder.query_exists ()) {
                settings.save_folder = Environment.get_user_special_dir (UserDirectory.VIDEOS);
            }

            mainwindow = new MainWindow ();
            mainwindow.set_application(this);
        }
    }
}


public static int main (string [] args) {
    Gst.init (ref args);
    var app = Screencast.ScreencastApp.instance;
    return app.run (args);
}
