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
    public class YellowCircle : Granite.Widgets.CompositedWindow {
        public YellowCircle (Gdk.RGBA color) {
            this.skip_pager_hint = true;
            this.skip_taskbar_hint = true;
            this.set_keep_above (true);
            this.stick ();
            this.type_hint = Gdk.WindowTypeHint.SPLASHSCREEN;
            this.accept_focus = false;

            this.draw.connect ((ctx) => {
                ctx.arc (this.get_allocated_width () / 2, this.get_allocated_height () / 2,
                        this.get_allocated_width () / 2, 0, 6.28318);
                ctx.set_source_rgba (color.red, color.green, color.blue, color.alpha);
                ctx.fill ();

                return false;
            });

            this.set_size_request (70, 70);
            this.realize ();
            this.get_window ().input_shape_combine_region (new Cairo.Region.rectangle ({ 0, 0, 1, 1 }), 0, 0);
            this.show_all ();
        }

        public new void move (int x, int y) {
            base.move (x - (int) (this.get_allocated_width () / 2), y - (int) (this.get_allocated_height () / 2));
        }
    }

    public class ClickWindow : Granite.Widgets.CompositedWindow {
        public ClickWindow (int x, int y, int button) {
            this.skip_pager_hint = true;
            this.skip_taskbar_hint = true;
            this.set_keep_above (true);
            this.stick ();
            this.type_hint = Gdk.WindowTypeHint.SPLASHSCREEN;
            this.accept_focus = false;

            string label = "";

            switch (button) {
                case 1:
                    label = _("Left");
                    break;
                case 2:
                    label = _("Middle");
                    break;
                case 3:
                    label = _("Right");
                    break;
                default:
                    break;
            }

            var lbl = new Gtk.Label (label);
            lbl.attributes = new Pango.AttrList ();
            lbl.attributes.insert (new Pango.AttrFontDesc (Pango.FontDescription.from_string ("16px")));

            this.add (lbl);

            var css = new Gtk.CssProvider ();

            try {
                css.load_from_data ("* { color:#fff; text-shadow:1 1 #000; }", -1);
            } catch (Error e) {
                warning (e.message);
            }

            lbl.get_style_context ().add_provider (css, 20000);

            this.realize ();
            this.get_window ().input_shape_combine_region (new Cairo.Region.rectangle ({ 0, 0, 1, 1 }), 0, 0);
            this.show_all ();
            this.move (x + 5, y + 5);

            Timeout.add (10, () => {
                this.opacity -= 0.007;

                // prevent flickering
                if (this.opacity < 0.1)
                    this.foreach ((c) => this.remove (c));
                if (this.opacity <= 0) {
                    this.destroy ();

                    return false;
                }

                return true;
            });
        }
    }

    public class Key : Gtk.Label {
        public string key;
        public bool ctrl;
        public bool shift;
        public bool alt;
        public bool super;
        public bool iso_level3_shift;
        public int count;

        public Key (string key, bool ctrl, bool shift, bool alt, bool super, bool iso_level3_shift){
            this.key = key;
            this.ctrl = ctrl;
            this.shift = shift;
            this.alt = alt;
            this.super = super;
            this.iso_level3_shift = iso_level3_shift;
            this.count = 1;
        }
    }


    public class KeyView : Granite.Widgets.CompositedWindow {
        public int key_size;
        public int fade_duration;

        private bool ctrl;
        private bool shift;
        private bool alt;
        private bool super;
        private bool iso_level3_shift;

        private int screen_h;

        public Queue<Key> keys;

        public YellowCircle circle;

        public Cairo.ImageSurface key_bg;

        [CCode (cname = "intercept_key_thread")]
        public extern void *intercept_key_thread ();

        public signal void captured (string keyvalue, bool released);
        public signal void captured_mouse (int x, int y, int button);
        public signal void captured_move (int x, int y);

        public override bool draw (Cairo.Context ctx){

            //key
            for (var i=0;i<keys.length;i++){
                ctx.set_source_surface (key_bg, 0, screen_h - (i+2)*key_size);
                ctx.paint ();

                ctx.set_source_rgba (1.0, 1.0, 1.0, 1.0);

                int [] sizes = {0, 30, 45, 55, 60};
                print ("%i\n", keys.peek_nth (i).key.length);

                if( keys.peek_nth (i).key.length >= sizes.length ) {
                    ctx.set_font_size (key_size - sizes[sizes.length - 1]);
                } else {
                    ctx.set_font_size (key_size - sizes[keys.peek_nth (i).key.length]);
                }

                ctx.move_to (key_size - 40, screen_h - (i + 1)*key_size - 20);
                ctx.show_text (keys.peek_nth (i).key);

                ctx.set_font_size (18);
                if (keys.peek_nth (i).count > 1){
                    ctx.move_to (3, screen_h - (i + 1) * key_size - (key_size - 12));
                    ctx.show_text (keys.peek_nth (i).count.to_string () + "x");
                }
                ctx.set_font_size (12);
                if (keys.peek_nth (i).super){
                    ctx.move_to (5, screen_h - (i + 1) * key_size - 52);
                    ctx.show_text ("Super");
                }
                if (keys.peek_nth (i).ctrl){
                    ctx.move_to (5, screen_h - (i + 1) * key_size - 37);
                    ctx.show_text ("Ctrl");
                }
                if (keys.peek_nth (i).shift){
                    ctx.move_to (5, screen_h - (i + 1) * key_size - 22);
                    ctx.show_text ("Shift");
                }
                if (keys.peek_nth (i).alt){
                    ctx.move_to (5, screen_h - (i + 1) * key_size - 7);
                    ctx.show_text ("Alt");
                }
                if (keys.peek_nth (i).iso_level3_shift) {
                    ctx.move_to (5, screen_h - (i + 1) * key_size - 12);
                    ctx.show_text ("AltGr");
                }
            }

            return base.draw (ctx);
        }

        public void place (int x, int y, int h) {
            this.set_size_request (key_size, h);
            this.resize (key_size, h);
            this.move (x - key_size, y);
            this.screen_h = h;
        }

        public KeyView (bool keyboard, bool mouse, bool mouse_circle, Gdk.RGBA mouse_circle_color) {
            this.key_size = 75;
            this.fade_duration = 2000;

            this.stick ();
            this.set_keep_above (true);
            this.deletable = false;
            this.resizable = false;
            this.set_has_resize_grip (false);
            this.skip_pager_hint = true;
            this.skip_taskbar_hint = true;
            this.accept_focus = false;

            this.type_hint = Gdk.WindowTypeHint.NOTIFICATION;
            this.events = Gdk.EventMask.BUTTON_MOTION_MASK | Gdk.EventMask.BUTTON1_MOTION_MASK |
                    Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK;

            this.realize ();

            Cairo.RectangleInt rect = { 0, 0, 1, 1 };

            this.get_window ().input_shape_combine_region (new Cairo.Region.rectangle (rect), 0, 0);

            this.enter_notify_event.connect (() => {
                this.get_window ().input_shape_combine_region (new Cairo.Region.rectangle (rect), 0, 0);

                return true;
            });

            this.keys = new Queue<Key> ();

            //setup the key background
            key_bg = new Cairo.ImageSurface (Cairo.Format.ARGB32, key_size, key_size);

            var ctx = new Cairo.Context (key_bg);

            Granite.Drawing.Utilities.cairo_rounded_rectangle (ctx, 5, 5, key_size-10, key_size - 10, 5);
            ctx.set_source_rgba (0.2, 0.2, 0.2, 0.7);
            ctx.fill_preserve ();

            capture ();

            Timeout.add (fade_duration, () => {
                if (!keys.is_empty ()) {
                    keys.pop_tail ();
                    this.queue_draw ();
                }

                return true;
            });

            if (mouse_circle) {
                this.circle = new YellowCircle (mouse_circle_color);
                this.captured_move.connect ((x, y) => {
                    Idle.add (() => {
                        this.circle.move (x, y);

                        return false;
                    });
                });
            }

            if (mouse) {
                this.captured_mouse.connect ((x, y, button) => {
                    debug ("Button %i pressed at %i, %i ", button, x, y);

                    if (button <= 3) {
                        Timeout.add (10, () => {
                            new ClickWindow (x, y, button);

                            return false;
                        });
                    }
                });
            }

            if (keyboard) {
                this.captured.connect ((keyvalue, released) => {
                    Idle.add (() => {
                        handle_key_event (keyvalue, released);

                        return false;
                    });
                });
            }
        }

        void handle_key_event (string keyvalue, bool released) {
            if (released) {
                switch (keyvalue) {
                    case "Control_L":
                    case "Control_R":
                        this.ctrl = false;
                        this.queue_draw ();
                        break;
                    case "Shift_L":
                    case "Shift_R":
                        this.shift = false;
                        this.queue_draw ();
                        break;
                    case "Alt_L":
                    case "Alt_R":
                        this.alt = false;
                        this.queue_draw ();
                        break;
                    case "Super_L":
                    case "Super_R":
                        this.super = false;
                        this.queue_draw ();
                        return;
                    case "ISO_Level3_Shift":
                        this.iso_level3_shift = false;
                        this.queue_draw ();
                        return;
                }
            } else {
                string res = keyvalue;

                switch (res) {
                    case "Control_L":
                    case "Control_R":
                        this.ctrl = true;
                        this.queue_draw ();
                        return;
                    case "Shift_L":
                    case "Shift_R":
                        this.shift = true;
                        this.queue_draw ();
                        return;
                    case "Alt_L":
                    case "Alt_R":
                        this.alt = true;
                        this.queue_draw ();
                        return;
                    case "Super_L":
                    case "Super_R":
                        this.super = true;
                        this.queue_draw ();
                        return;
                    case "ISO_Level3_Shift":
                        this.iso_level3_shift = true;
                        this.queue_draw ();
                        return;
                    case "Escape":
                        res = "Esc";
                        break;
                    case "Return":
                        res = "⏎";
                        break;
                    case "Delete":
                        res = "Del";
                        break;
                    case "Insert":
                        res = "Ins";
                        break;
                    case "comma":
                        res = ",";
                        break;
                    case "period":
                        res = ".";
                        break;
                    case "minus":
                        res = "-";
                        break;
                    case "plus":
                        res = "+";
                        break;
                    case "Tab":
                        res = "Tab";
                        break;
                    case "BackSpace":
                        res = "⌫";
                        break;
                    case "Left":
                        res = "◄";
                        break;
                    case "Right":
                        res = "►";
                        break;
                    case "Up":
                        res = "▲";
                        break;
                    case "Down":
                        res = "▼";
                        break;
                    case "space":
                        res = " ";
                        break;
                    case "backslash":
                        res = "\\";
                        break;
                    case "bracketleft":
                        res = "[";
                        break;
                    case "bracketright":
                        res = "]";
                        break;
                    case "braceleft":
                        res = "{";
                        break;
                    case "braceright":
                        res = "}";
                        break;
                    case "apostrophe":
                        res = "'";
                        break;
                    case "asciitilde":
                        res = "~";
                        break;
                    case "grave":
                        res = "`";
                        break;
                    case "bar":
                        res = "|";
                        break;
                    case "ampersand":
                        res = "&";
                        break;
                    case "parenleft":
                        res = "(";
                        break;
                    case "parenright":
                        res = ")";
                        break;
                    case "less":
                        res = "<";
                        break;
                    case "greater":
                        res = ">";
                        break;
                    case "equal":
                        res = "=";
                        break;
                    case "exclam":
                        res = "!";
                        break;
                    case "quotedbl":
                        res = "\"";
                        break;
                    case "numbersign":
                        res = "\"";
                        break;
                    case "dollar":
                        res = "$";
                        break;
                    case "slash":
                        res = "/";
                        break;
                    case "asterisk":
                        res = "*";
                        break;
                    case "colon":
                        res = ":";
                        break;
                    case "semicolon":
                        res = ";";
                        break;
                    case "underscore":
                        res = "_";
                        break;
                    case "Next":
                        res = "Pg▲";
                        break;
                    case "Prior":
                        res = "Pg▼";
                        break;
                    case "asciicircum":
                        res = "^";
                        break;
                    case "at":
                        res = "@";
                        break;
                    case "question":
                        res = "?";
                        break;
                    default:
                        if (keyvalue.length > 9)
                            res = keyvalue.substring (0, 9);
                        break;
                }

                if ((!keys.is_empty ())
                    && (keys.peek_head ().key == res)
                    && (keys.peek_head ().ctrl == ctrl)
                    && (keys.peek_head ().shift == shift)
                    && (keys.peek_head ().alt == alt)
                    && (keys.peek_head ().iso_level3_shift == iso_level3_shift)) {
                    keys.peek_head ().count++;

                    this.queue_draw ();
                } else {
                    var key = new Key (res, ctrl, shift, alt, super, iso_level3_shift);

                    if (!released) {
                        keys.push_head (key);

                        if (keys.length + 2 > (screen_h / key_size))
                            keys.pop_tail ();

                        this.queue_draw ();
                    }
                }
            }
        }

        public void capture () {
            try {
                Thread.create<void*> (this.intercept_key_thread, true);
            } catch (ThreadError e) {
                stderr.printf (e.message);
            }
        }
    }
}

