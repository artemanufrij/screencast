/*-
 * Copyright (c) 2018-2018 Artem Anufrij <artem.anufrij@live.de>
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

namespace Screencast.Interfaces {
    [DBus (name = "org.gnome.SettingsDaemon.MediaKeys")]
    public interface GnomeMediaKeys : GLib.Object {
        public abstract void GrabMediaPlayerKeys (string application, uint32 time) throws Error;
        public abstract void ReleaseMediaPlayerKeys (string application) throws Error;
        public signal void MediaPlayerKeyPressed (string application, string key);
    }

    public class MediaKeyListener : GLib.Object {
        public static MediaKeyListener instance { get; private set; }
        private GnomeMediaKeys ? media_keys;

        construct {
            assert (media_keys == null);
            try {
                media_keys = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.SettingsDaemon", "/org/gnome/SettingsDaemon/MediaKeys");
            } catch (Error e) {
                warning ("Mediakeys error: %s", e.message);
            }

            if (media_keys != null) {
                media_keys.MediaPlayerKeyPressed.connect (pressed_key);
                try {
                    media_keys.GrabMediaPlayerKeys (ScreencastApp.instance.application_id, (uint32)0);
                }
                catch (Error err) {
                    warning ("Could not grab media player keys: %s", err.message);
                }
            }
        }

        private MediaKeyListener () {
        }

        public static void listen () {
            instance = new MediaKeyListener ();
        }

        private void pressed_key (dynamic Object bus, string application, string key) {
            if (application == (ScreencastApp.instance.application_id)) {
                if (key == "Play") {
                    ScreencastApp.instance.mainwindow.toggle_recording ();
                } else if (key == "Stop") {
                    ScreencastApp.instance.mainwindow.stop_recording ();
                } else if (key == "Pause") {
                    ScreencastApp.instance.mainwindow.pause_recording ();
                }
            }
        }
    }
}
