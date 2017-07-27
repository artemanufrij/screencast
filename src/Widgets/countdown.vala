//
//  Copyright (C) 2011-2015 Eidete Developers
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Eidete.Widgets {
    public class Countdown : Granite.Widgets.CompositedWindow {
        public Gtk.Label count;
        public int time;

        public Countdown () {
            this.time = 5;

            this.set_default_size (300, 200);
            this.window_position = Gtk.WindowPosition.CENTER;
            this.set_keep_above (true);
            this.stick ();
            this.type_hint = Gdk.WindowTypeHint.SPLASHSCREEN;
            this.skip_pager_hint = true;
            this.skip_taskbar_hint = true;

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.margin = 40;
            box.margin_left = box.margin_right = 60;

            var title = new Gtk.Label ("<span size='20000' color='#fbfbfb'>" + _("Recording starts in") + "…" + "</span>");
            title.use_markup = true;
            title.margin_bottom = 20;

            this.count = new Gtk.Label ("<span size='40000' color='#fbfbfb'>" + time.to_string () + "</span>");
            this.count.use_markup = true;

            var tipp = new Gtk.Label("<span size='10000' color='#fbfbfb' font-style='italic'>" + _("Focus Eidete to stop recording") + "</span>");
            tipp.use_markup = true;
            tipp.margin_top = 20;

            box.pack_start (title);
            box.pack_start (count);
            box.pack_start (tipp);

            this.add (box);
        }

        public override bool draw (Cairo.Context ctx) {
            int w = this.get_allocated_width ();
            int h = this.get_allocated_height ();

            Granite.Drawing.Utilities.cairo_rounded_rectangle (ctx, 4, 4, w - 8, h - 8, 4);

            ctx.set_source_rgba (0.1, 0.1, 0.1, 0.8);
            ctx.fill ();

            return base.draw (ctx);
        }

        public void start (EideteApp app) {
            this.show_all ();

            Timeout.add (1000, () => {
                this.time--;

                count.label = "<span size='40000' color='#fbfbfb'>" + time.to_string () + "</span>";

                if (time == -1) {
                    this.destroy ();

                    // let the countdown disappear before starting
                    Timeout.add (100, () => {
                        app.record ();
                        app.main_window.iconify ();
                        app.switch_to_paused (false);

                        return false;
                    });

                    return false;
                }

                return true;
            });
        }
    }
}

