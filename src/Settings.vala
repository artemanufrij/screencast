/*-
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

public class Screencast.Settings : Granite.Services.Settings {
    private static Settings settings;
    public static Settings get_default () {
        if (settings == null)
            settings = new Settings ();

        return settings;
    }

    public int sx { get; set; }
    public int sy { get; set; }
    public int ex { get; set; }
    public int ey { get; set; }
    public int monitor { get; set; }
    public int delay { get; set; }
    public bool audio { get; set; }
    public bool sound { get; set; }
    public bool keyview { get; set; }
    public bool clickview { get; set; }
    public bool mouse_circle { get; set; }
    public string mouse_circle_color { get; set; }
    public string destination { get; set; }
    public string save_folder { get; set; }

    private Settings () {
        base ("com.github.artemanufrij.screencast");
    }
}
