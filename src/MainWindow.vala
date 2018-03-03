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
    class LLabel : Gtk.Label {
        public LLabel (string label) {
            this.set_halign (Gtk.Align.START);
            this.label = label;
        }

        public LLabel.markup (string label) {
            this (label);
            this.use_markup = true;
        }

        public LLabel.right (string label) {
            this.set_halign (Gtk.Align.END);
            this.label = label;
        }
    }

    public class MainWindow : Gtk.ApplicationWindow {
        public dynamic Gst.Pipeline pipeline;

        public Screencast.Widgets.KeyView keyview;
        public Screencast.Widgets.SelectionArea selectionarea;
        private Gtk.Stack tabs;
        private Gtk.Grid main_box;
        private Gtk.Box home_buttons;
        private Gtk.StackSwitcher stack_switcher;
        private Gtk.ComboBoxText recordingarea_combo;
        public Wnck.Window win;
        public Gdk.Rectangle monitor_rec;

        public Settings settings;
        AppIndicator.Indicator indicator;
        Gtk.MenuItem toggle_item;

        public bool recording;
        public bool typing_size;
        private int scale;

        public Gst.Bin videobin;
        public Gst.Bin audiobin;

        public MainWindow () {
            start_and_build ();
        }

        public void start_and_build () {
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;

            settings = Settings.get_default ();

            this.screen = Gdk.Screen.get_default ();
            this.icon_name = "artemanufrij.screencast";
            this.window_position = Gtk.WindowPosition.CENTER;
            this.resizable = false;
            var headerbar = new Gtk.HeaderBar ();
            headerbar.title = _ ("Screencast");
            headerbar.get_style_context ().add_class ("flat");
            headerbar.show_close_button = true;
            this.set_titlebar (headerbar);


            if (!this.is_composited ()) {
                warning ("Compositing is not supported. No transparency available.");
            }

            tabs = new Gtk.Stack ();

            var grid = new Gtk.Grid ();
            grid.column_spacing = 12;
            grid.row_spacing = 6;
            grid.hexpand = false;

            var monitors_combo = new Gtk.ComboBoxText ();
            monitors_combo.hexpand = true;

            for (var i = 0; i < screen.get_n_monitors (); i++) {
                monitors_combo.append (i.to_string (), _ ("Monitor %d").printf (i + 1));
            }

            monitors_combo.active = 0;

            if (screen.get_n_monitors () == 1)
                monitors_combo.set_sensitive (false);

            var primary = screen.get_primary_monitor ();
            scale = screen.get_monitor_scale_factor (primary);
            var width = new Gtk.SpinButton.with_range (50, screen.get_width () * scale, 1);
            width.max_length = 4;
            width.margin_left = 1;

            var height = new Gtk.SpinButton.with_range (50, screen.get_height () * scale, 1);
            height.max_length = 4;
            height.margin_left = 1;
            width.set_sensitive (false);
            height.set_sensitive (false);
            width.halign = Gtk.Align.START;
            height.halign = Gtk.Align.START;

            recordingarea_combo = new Gtk.ComboBoxText ();
            recordingarea_combo.append ("full", _ ("Fullscreen"));
            recordingarea_combo.append ("custom", _ ("Custom"));
            recordingarea_combo.active = 0;

            var use_sound = new Gtk.Switch ();
            use_sound.halign = Gtk.Align.START;
            use_sound.valign = Gtk.Align.CENTER;

            var sound_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            sound_box.pack_start (use_sound, false, true, 0);

            var use_audio = new Gtk.Switch ();
            use_audio.halign = Gtk.Align.START;
            use_audio.valign = Gtk.Align.CENTER;

            var audio_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            audio_box.pack_start (use_audio, false, true, 0);

            var sound = new LLabel.markup ("<b>" + _ ("Sound") + "</b>");
            sound.margin_top = 18;

            var video = new LLabel.markup ("<b>" + _ ("Video") + "</b>");
            video.margin_top = 12;

            var keyboard = new LLabel.markup ("<b>" + _ ("Keyboard") + "</b>");
            keyboard.margin_top = 18;

            var mouse = new LLabel.markup ("<b>" + _ ("Mouse") + "</b>");
            mouse.margin_top = 12;

            grid.attach (sound, 0, 0, 1, 1);
            grid.attach (new LLabel.right (_ ("Record Computer Sounds:")), 0, 1, 1, 1);
            grid.attach (sound_box, 1, 1, 1, 1);
            grid.attach (new LLabel.right (_ ("Record from Microphone:")), 0, 2, 1, 1);
            grid.attach (audio_box, 1, 2, 1, 1);
            grid.attach ((video), 0, 3, 2, 1);
            grid.attach (new LLabel.right (_ ("Record from Monitor:")), 0, 4, 1, 1);
            grid.attach (monitors_combo, 1, 4, 1, 1);
            grid.attach (new LLabel.right (_ ("Recording Area:")), 0, 5, 1, 1);
            grid.attach (recordingarea_combo, 1, 5, 1, 1);
            grid.attach (new LLabel.right (_ ("Width:")), 0, 6, 1, 1);
            grid.attach (width, 1, 6, 1, 1);
            grid.attach (new LLabel.right (_ ("Height:")), 0, 7, 1, 1);
            grid.attach (height, 1, 7, 1, 1);

            // grid2
            var grid2 = new Gtk.Grid ();

            var use_keyview = new Gtk.Switch ();
            use_keyview.halign = Gtk.Align.START;

            var use_clickview = new Gtk.Switch ();
            use_clickview.halign = Gtk.Align.START;

            var use_circle = new Gtk.Switch ();
            use_circle.halign = Gtk.Align.START;

            var circle_color = new Gtk.ColorButton ();
            circle_color.margin_left = 4;

            var circle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            circle_box.pack_start (use_circle, false);
            circle_box.pack_start (circle_color);

            grid2.attach ((keyboard), 0, 0, 1, 1);
            grid2.attach (new LLabel.right (_ ("Pressed keys on screen:")), 0, 1, 1, 1);
            grid2.attach (use_keyview, 1, 1, 1, 1);
            grid2.attach ((mouse), 0, 2, 1, 1);
            grid2.attach (new LLabel.right (_ ("Mouse clicks on screen:")), 0, 3, 1, 1);
            grid2.attach (use_clickview, 1, 3, 1, 1);
            grid2.attach (new LLabel.right (_ ("Circle around the cursor:")), 0, 4, 1, 1);
            grid2.attach (circle_box, 1, 4, 1, 1);
            grid2.column_spacing = 12;
            grid2.row_spacing = 6;
            grid2.hexpand = true;

            tabs.add_titled (grid, "behavior", _ ("Behavior"));
            tabs.add_titled (grid2, "apperance", _ ("Appearance"));

            main_box = new Gtk.Grid ();
            stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.stack = tabs;
            stack_switcher.halign = Gtk.Align.CENTER;

            main_box.attach (stack_switcher, 0, 0, 1, 1);
            main_box.attach (tabs, 0, 1, 1, 1);

            var start_bt = new Gtk.Button.with_label (_ ("Start Recording"));
            start_bt.can_default = true;
            start_bt.get_style_context ().add_class ("noundo");
            start_bt.get_style_context ().add_class ("suggested-action");

            var cancel_bt = new Gtk.Button.with_label (_ ("Close"));

            home_buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
            home_buttons.homogeneous = true;
            home_buttons.pack_start (cancel_bt, false, true, 0);
            home_buttons.pack_end (start_bt, false, true, 0);
            home_buttons.margin_top = 24;

            main_box.attach (home_buttons, 0, 3, 1, 1);
            main_box.margin = 12;

            this.add (main_box);

            this.show_all ();
            this.set_default (start_bt);
            this.present ();

            /*
               Events
             */

            cancel_bt.clicked.connect (() => { this.destroy (); });
            start_bt.clicked.connect (start_cowndown);

            settings.monitor = 0;
            monitors_combo.changed.connect (
                () => {
                    settings.monitor = int.parse (monitors_combo.active_id);

                    this.screen.get_monitor_geometry (settings.monitor, out this.monitor_rec);
                    var _scale = screen.get_monitor_scale_factor (settings.monitor);

                    settings.sx = this.monitor_rec.x * _scale;
                    settings.sy = this.monitor_rec.y * _scale;
                    settings.ex = settings.sx + this.monitor_rec.width * _scale - 1;
                    settings.ey = settings.sy + this.monitor_rec.height * _scale - 1;
                });

            settings.monitor = int.parse (monitors_combo.active_id);

            this.screen.get_monitor_geometry (settings.monitor, out this.monitor_rec);
            scale = screen.get_monitor_scale_factor (settings.monitor);

            recordingarea_combo.changed.connect (
                () => {
                    if (recordingarea_combo.active_id != "full") {
                        selectionarea = new Screencast.Widgets.SelectionArea ();

                        int rec_widht = settings.ex - settings.sx;
                        if (rec_widht < 50) {
                            rec_widht = 50;
                        }

                        int rec_height = settings.ey - settings.sy;
                        if (rec_height < 50) {
                            rec_height = 50;
                        }
                        selectionarea.resize (rec_widht, rec_height);
                        selectionarea.move (settings.sx, settings.sy);

                        selectionarea.show_all ();
                        width.sensitive = true;
                        height.sensitive = true;
                        selectionarea.geometry_changed.connect (
                            (x, y, w, h) => {
                                if (!typing_size) {
                                    width.value  = (int)w;
                                    height.value = (int)h;
                                    settings.sx = x;
                                    settings.sy = y;
                                    settings.ex = settings.sx + w - 1;
                                    settings.ey = settings.sy + h - 1;
                                }
                            });

                        selectionarea.focus_in_event.connect (
                            (ev) => {
                                if (this.recording) {
                                    this.deiconify ();
                                    this.present ();
                                }

                                return false;
                            });
                    } else {
                        selectionarea.destroy ();
                        settings.monitor = int.parse (monitors_combo.active_id);

                        this.screen.get_monitor_geometry (settings.monitor, out this.monitor_rec);
                        var _scale = screen.get_monitor_scale_factor (settings.monitor);

                        settings.sx = this.monitor_rec.x * _scale;
                        settings.sy = this.monitor_rec.y * _scale;
                        settings.ex = settings.sx + this.monitor_rec.width * _scale - 1;
                        settings.ey = settings.sy + this.monitor_rec.height * _scale - 1;

                        width.sensitive = false;
                        height.sensitive = false;
                    }
                });

            width.value_changed.connect (
                () => {
                    selectionarea.resize ((int)width.value, (int)height.value);
                });

            height.value_changed.connect (
                () => {
                    selectionarea.resize ((int)width.value, (int)height.value);
                });

            use_sound.state = settings.sound;
            use_sound.state_set.connect (
                (state) => {
                    settings.sound = state;
                    return false;
                });

            use_audio.state = settings.audio;
            use_audio.state_set.connect (
                (state) => {
                    settings.audio = state;
                    return false;
                });

            Gdk.Screen.get_default ().monitors_changed.connect (
                () => {
                    if (Gdk.Screen.get_default ().get_n_monitors () > 1) {
                        monitors_combo.set_sensitive (true);
                    } else {
                        monitors_combo.set_sensitive (false);
                    }
                });

            use_keyview.state = settings.keyview;
            use_keyview.state_set.connect (
                (state) => {
                    settings.keyview = state;
                    return false;
                });

            use_clickview.state = settings.clickview;
            use_clickview.state_set.connect (
                (state) => {
                    settings.clickview = state;
                    return false;
                });

            use_circle.state = settings.mouse_circle;
            use_circle.state_set.connect (
                (state) => {
                    settings.mouse_circle = state;
                    return false;
                });

            circle_color.use_alpha = true;

            Gdk.RGBA circle = { 0, 0, 0, 0};
            circle.parse (settings.mouse_circle_color);
            circle_color.rgba = circle;

            circle_color.color_set.connect (
                () => {
                    settings.mouse_circle_color = circle_color.rgba.to_string ();
                });

            this.focus_in_event.connect (
                (ev) => {
                    if (this.selectionarea != null && !this.selectionarea.not_visible) {
                        this.selectionarea.present ();
                        this.present ();
                    }

                    return false;
                });

            this.destroy.connect (
                () => {
                    if (recording) {
                        stop_recording ();
                    }
                    if (selectionarea != null) {
                        selectionarea.destroy ();
                    }
                });

            create_indicator ();
        }

        private bool bus_message_cb (Gst.Bus bus, Gst.Message msg) {
            switch (msg.type) {
            case Gst.MessageType.ERROR :
                GLib.Error err;

                string debug;

                msg.parse_error (out err, out debug);

                display_error ("Screencast encountered a gstreamer error while recording, creating a screencast is not possible:\n%s\n\n[%s]".printf (err.message, debug), true);
                stderr.printf ("Error: %s\n", debug);
                pipeline.set_state (Gst.State.NULL);

                break;
            case Gst.MessageType.EOS :
                debug ("received EOS");

                pipeline.set_state (Gst.State.NULL);

                this.recording = false;

                save_file ();
                pipeline = null;
                break;
            default :
                break;
            }

            return true;
        }

        private bool save_file () {
            debug (settings.save_folder);

            var dialog = new Gtk.FileChooserDialog (_ ("Save"), this, Gtk.FileChooserAction.SAVE, _ ("OK"), Gtk.ResponseType.OK);

            var date_time = new GLib.DateTime.now_local ().format ("%Y-%m-%d %H.%M.%S");
            var file_name = _ ("Screencast from %s").printf (date_time);

            dialog.set_current_name (file_name + ".webm");
            dialog.set_current_folder (settings.save_folder);
            dialog.do_overwrite_confirmation = true;

            var res = dialog.run ();

            if (res == Gtk.ResponseType.OK) {
                var destination = File.new_for_path (dialog.get_filename ());
                try {
                    var source = File.new_for_path (settings.destination);
                    source.move (destination, FileCopyFlags.OVERWRITE);
                    settings.save_folder = destination.get_parent ().get_path ();
                } catch (GLib.Error e) {
                    stderr.printf ("Error: %s\n", e.message);
                }
            }

            dialog.destroy ();

            return res == Gtk.ResponseType.OK;
        }

        public void create_indicator () {
            indicator = new AppIndicator.Indicator ("screencast", "media-playback-stop-symbolic", AppIndicator.IndicatorCategory.APPLICATION_STATUS);
            indicator.set_status (AppIndicator.IndicatorStatus.ACTIVE);

            var menu = new Gtk.Menu ();
            toggle_item = new Gtk.MenuItem.with_label (_ ("Start Recording"));
            toggle_item.activate.connect (
                () => {
                    toggle_recording ();
                });
            menu.append (toggle_item);

            var stop_item = new Gtk.MenuItem.with_label (_ ("Finish"));
            stop_item.activate.connect (
                () => {
                    stop_recording ();
                });
            menu.append (stop_item);

            menu.append (new Gtk.SeparatorMenuItem ());

            var quit_item = new Gtk.MenuItem.with_label (_ ("Cancel"));
            quit_item.activate.connect (
                () => {
                    ScreencastApp.instance.quit ();
                });
            menu.append (quit_item);

            menu.show_all ();
            indicator.set_menu (menu);
        }

        private void display_error (string error, bool fatal) {
            var dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, error);
            dialog.show_all ();
            dialog.response.connect (
                () => {
                    dialog.destroy ();
                    if (fatal) {
                        this.destroy ();
                    }
                });
            dialog.run ();
        }

        public void set_icolabel (string icon, string label) {
            indicator.set_icon_full (icon, icon);
            indicator.label = label;
        }

        public void start_cowndown () {
            var count = new Screencast.Widgets.Countdown ();
            this.iconify ();
            count.start ();
        }

        public void pause_recording () {
            pipeline.set_state (Gst.State.PAUSED);
            this.recording = false;
            set_icolabel ("media-playback-pause-symbolic", "");
            toggle_item.label = _ ("Continue");
        }

        public void stop_recording () {
            if (!this.recording) {
                debug ("resuming recording");
                this.pipeline.set_state (Gst.State.PLAYING);
                this.recording = true;
            }
            pipeline.send_event (new Gst.Event.eos ());
            set_icolabel ("media-playback-stop-symbolic", "");
        }

        public void toggle_recording () {
            if (pipeline == null) {
                start_cowndown ();
            } else if (this.recording) {
                pause_recording ();
            } else {
                continue_recording ();
            }
        }

        public void continue_recording () {
            this.iconify ();
            this.pipeline.set_state (Gst.State.PLAYING);
            this.recording = true;

            set_icolabel ("media-record-symbolic", "");
            toggle_item.label = _ ("Pause");

            if (settings.keyview || settings.clickview || settings.mouse_circle) {
                keyview.place (settings.ex, settings.sy, settings.ey - settings.sy);
                keyview.show_all ();
            }
        }

        public void start_recording () {
            if (settings.keyview || settings.clickview || settings.mouse_circle) {
                Gdk.RGBA circle = { 0, 0, 0, 0};
                circle.parse (settings.mouse_circle_color);
                keyview = new Screencast.Widgets.KeyView (settings.keyview, settings.clickview, settings.mouse_circle, circle);
                keyview.focus_in_event.connect (
                    (ev) => {
                        if (this.recording) {
                            this.deiconify ();
                            this.present ();
                        }
                        return false;
                    });

                keyview.place (settings.ex, settings.sy, settings.ey - settings.sy);
                keyview.show_all ();
            }

            pipeline = new Gst.Pipeline ("screencast-pipe");

            var muxer = Gst.ElementFactory.make ("webmmux", "mux");
            var sink = Gst.ElementFactory.make ("filesink", "sink");

            // video bin
            this.videobin = new Gst.Bin ("video");

            try {
                videobin = (Gst.Bin)Gst.parse_bin_from_description ("ximagesrc name=\"videosrc\" ! video/x-raw, framerate=24/1 ! videoconvert ! vp8enc name=\"encoder\" ! queue", true);
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }

            // audio bin
            this.audiobin = new Gst.Bin ("audio");

            string default_output = "";
            try {
                string sound_outputs = "";
                Process.spawn_command_line_sync ("pacmd list-sinks", out sound_outputs);
                GLib.Regex re = new GLib.Regex ("(?<=\\*\\sindex:\\s\\d\\s\\sname:\\s<)[\\w\\.\\-]*");
                MatchInfo mi;
                if (re.match (sound_outputs, 0, out mi)) {
                    default_output = mi.fetch (0);
                }
            } catch (Error e) {
                warning (e.message);
            }

            try {
                if (settings.audio && settings.sound && default_output != "") {
                    audiobin = (Gst.Bin)Gst.parse_bin_from_description ("adder name=mux ! audioconvert ! audioresample ! vorbisenc pulsesrc ! queue ! mux. pulsesrc device=" + default_output + ".monitor ! queue ! mux.", true);
                } else if (settings.audio) {
                    audiobin = (Gst.Bin)Gst.parse_bin_from_description ("pulsesrc name=\"audiosrc\" ! audioconvert ! vorbisenc ! queue", true);
                } else if (settings.sound && default_output != "") {
                    audiobin = (Gst.Bin)Gst.parse_bin_from_description ("pulsesrc device=" + default_output + ".monitor ! audioconvert ! vorbisenc ! queue", true);
                }
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }

            string cores;

            try {
                Process.spawn_command_line_sync ("cat /sys/devices/system/cpu/online", out cores);
            } catch (Error e) {
                warning (e.message);
            }

            //configure
            assert (sink != null);
            settings.destination = GLib.Environment.get_tmp_dir () + "/screencast_" + new GLib.DateTime.now_local ().to_unix ().to_string () + ".webm";
            sink.set ("location", settings.destination);

            var src = videobin.get_by_name ("videosrc");

            assert (src != null);

            int startx = this.monitor_rec.x * scale;
            int starty = this.monitor_rec.y * scale;
            int endx = settings.sx + this.monitor_rec.width * scale - 1;
            int endy = settings.sy + this.monitor_rec.height * scale - 1;

            if (recordingarea_combo.active_id != "full") {
                startx = settings.sx;
                starty = settings.sy;
                endx = settings.ex;
                endy = settings.ey;
            }
            src.set ("startx", startx);
            src.set ("starty", starty);
            src.set ("endx",   endx);
            src.set ("endy",   endy);
            src.set ("use-damage", false);
            src.set ("display-name", this.settings.monitor);

            // videobin.get_by_name ("encoder").set  ("mode", 1);
            var encoder = videobin.get_by_name ("encoder");

            assert (encoder != null);

            // From these values see https://mail.gnome.org/archives/commits-list/2012-September/msg08183.html
            encoder.set ("min_quantizer", 13);
            encoder.set ("max_quantizer", 13);
            encoder.set ("cpu-used", 5);
            encoder.set ("deadline", 1000000);
            encoder.set ("threads", int.parse (cores.substring (2)));

            if (pipeline == null || muxer == null || sink == null || videobin == null || audiobin == null) {
                stderr.printf ("Error: Elements weren't made correctly!\n");
            }

            if (settings.audio || (settings.sound && default_output != "")) {
                pipeline.add_many (audiobin, videobin, muxer, sink);
            } else {
                pipeline.add_many (videobin, muxer, sink);
            }

            videobin.get_static_pad ("src").link (muxer.get_request_pad ("video_%u"));

            if (settings.audio || (settings.sound && default_output != "")) {
                audiobin.get_static_pad ("src").link (muxer.get_request_pad ("audio_%u"));
            }

            muxer.link (sink);

            pipeline.get_bus ().add_watch (Priority.DEFAULT, bus_message_cb);

            pipeline.set_state (Gst.State.READY);

            if (selectionarea != null) {
                selectionarea.to_discrete ();
            }

            pipeline.set_state (Gst.State.PLAYING);
            this.recording = true;

            this.iconify ();
            set_icolabel ("media-record-symbolic", "");
            toggle_item.label = _ ("Pause");
        }
    }
}
