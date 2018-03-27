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
    class LLabel : Gtk.Label {
        public LLabel (string label) {
            this.set_halign (Gtk.Align.START);
            this.label = label;
        }

        public LLabel.right (string label) {
            this.set_halign (Gtk.Align.END);
            this.label = label;
        }
    }

    public class MainWindow : Gtk.Dialog {
        dynamic Gst.Pipeline pipeline;
        Gst.Bin videobin;
        Gst.Bin audiobin;

        Settings settings;

        Screencast.Widgets.KeyView keyview;
        Screencast.Widgets.SelectionArea selectionarea;
        Gtk.Stack tabs;
        Gtk.StackSwitcher stack_switcher;
        Gtk.Grid recording_controls;
        Gtk.Button rec_finish;
        Gtk.ComboBoxText recordingarea_combo;
        Gdk.Rectangle monitor_rec;

        AppIndicator.Indicator indicator;
        Gtk.MenuItem toggle_item;

        public bool recording { get; private set; default = false; }
        bool typing_size;
        int scale;

        construct {
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            settings = Settings.get_default ();
        }

        public MainWindow () {
            Object (use_header_bar: 1);
            start_and_build ();
        }

        public void start_and_build () {
            this.deletable = false;

            this.screen = Gdk.Screen.get_default ();
            this.window_position = Gtk.WindowPosition.CENTER;
            this.resizable = false;

            if (!this.is_composited ()) {
                warning ("Compositing is not supported. No transparency available.");
            }

            tabs = new Gtk.Stack ();
            tabs.margin = 12;

            var general = new Gtk.Grid ();
            general.column_spacing = 12;
            general.row_spacing = 6;

            var monitors_combo = new Gtk.ComboBoxText ();
            monitors_combo.hexpand = true;

            for (var i = 0; i < screen.get_n_monitors (); i++) {
                monitors_combo.append (i.to_string (), _ ("Monitor %d").printf (i + 1));
            }

            monitors_combo.active = 0;
            settings.monitor = 0;

            if (screen.get_n_monitors () == 1) {
                monitors_combo.set_sensitive (false);
            }

            var primary = screen.get_primary_monitor ();
            scale = screen.get_monitor_scale_factor (primary);

            var width = new Gtk.SpinButton.with_range (50, screen.get_width () * scale, 1);
            width.max_length = 4;
            width.sensitive = false;
            width.value = settings.ex - settings.sx;

            var height = new Gtk.SpinButton.with_range (50, screen.get_height () * scale, 1);
            height.max_length = 4;
            height.sensitive = false;
            height.value = settings.ey - settings.sy;

            recordingarea_combo = new Gtk.ComboBoxText ();
            recordingarea_combo.append ("full", _ ("Fullscreen"));
            recordingarea_combo.append ("custom", _ ("Custom"));
            recordingarea_combo.active = 0;

            var use_sound = new Gtk.Switch ();
            use_sound.halign = Gtk.Align.START;

            var sound_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            sound_box.pack_start (use_sound, false, true, 0);

            var use_audio = new Gtk.Switch ();
            use_audio.halign = Gtk.Align.START;

            var audio_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            audio_box.pack_start (use_audio, false, true, 0);

            var sound = new LLabel (_ ("Sound"));
            sound.get_style_context ().add_class ("h4");

            var video = new LLabel (_ ("Video"));
            video.get_style_context ().add_class ("h4");

            var keyboard = new LLabel (_ ("Keyboard"));
            keyboard.get_style_context ().add_class ("h4");

            var mouse = new LLabel (_ ("Mouse"));
            mouse.get_style_context ().add_class ("h4");

            var delay = new LLabel (_ ("Delay"));
            delay.get_style_context ().add_class ("h4");

            general.attach (sound, 0, 0, 1, 1);
            general.attach (new LLabel.right (_ ("Record computer sounds:")), 0, 1, 1, 1);
            general.attach (sound_box, 1, 1, 1, 1);
            general.attach (new LLabel.right (_ ("Record from microphone:")), 0, 2, 1, 1);
            general.attach (audio_box, 1, 2, 1, 1);
            general.attach (video, 0, 3, 2, 1);
            general.attach (new LLabel.right (_ ("Record from monitor:")), 0, 4, 1, 1);
            general.attach (monitors_combo, 1, 4, 1, 1);
            general.attach (new LLabel.right (_ ("Recording area:")), 0, 5, 1, 1);
            general.attach (recordingarea_combo, 1, 5, 1, 1);
            general.attach (new LLabel.right (_ ("Width:")), 0, 6, 1, 1);
            general.attach (width, 1, 6, 1, 1);
            general.attach (new LLabel.right (_ ("Height:")), 0, 7, 1, 1);
            general.attach (height, 1, 7, 1, 1);

            var apperance = new Gtk.Grid ();
            apperance.column_spacing = 12;
            apperance.row_spacing = 6;

            var use_keyview = new Gtk.Switch ();
            use_keyview.halign = Gtk.Align.START;

            var use_clickview = new Gtk.Switch ();
            use_clickview.halign = Gtk.Align.START;

            var use_circle = new Gtk.Switch ();
            use_circle.halign = Gtk.Align.START;

            var circle_color = new Gtk.ColorButton ();

            var circle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
            circle_box.pack_start (use_circle, false);
            circle_box.pack_start (circle_color);

            var delay_spin = new Gtk.SpinButton.with_range (1, 10, 1);
            delay_spin.max_length = 4;
            delay_spin.halign = Gtk.Align.START;
            delay_spin.value = settings.delay;
            delay_spin.value_changed.connect (
                () => {
                    settings.delay = (int)delay_spin.value;
                });

            apperance.attach (keyboard, 0, 0, 1, 1);
            apperance.attach (new LLabel.right (_ ("Pressed keys on screen:")), 0, 1, 1, 1);
            apperance.attach (use_keyview, 1, 1, 1, 1);
            apperance.attach (mouse, 0, 2, 1, 1);
            apperance.attach (new LLabel.right (_ ("Mouse clicks on screen:")), 0, 3, 1, 1);
            apperance.attach (use_clickview, 1, 3, 1, 1);
            apperance.attach (new LLabel.right (_ ("Circle around the cursor:")), 0, 4, 1, 1);
            apperance.attach (circle_box, 1, 4, 1, 1);
            apperance.attach (delay, 0, 5, 1, 1);
            apperance.attach (new LLabel.right (_ ("Delay in seconds:")), 0, 6, 1, 1);
            apperance.attach (delay_spin, 1, 6, 1, 1);

            tabs.add_titled (general, "behavior", _ ("Behavior"));
            tabs.add_titled (apperance, "apperance", _ ("Appearance"));

            Gtk.Box content = this.get_content_area () as Gtk.Box;

            stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.stack = tabs;
            stack_switcher.margin_top = 12;

            var header = this.get_header_bar () as Gtk.HeaderBar;
            header.get_style_context ().add_class ("default-decoration");
            header.set_custom_title (stack_switcher);

            recording_controls = new Gtk.Grid ();
            recording_controls.column_homogeneous = true;
            recording_controls.column_spacing = 12;
            recording_controls.row_spacing = 12;
            recording_controls.margin = 12;
            recording_controls.valign = Gtk.Align.CENTER;

            var img_cancel = new Gtk.Image.from_icon_name ("edit-delete", Gtk.IconSize.DIALOG);
            var rec_cancel = new Gtk.Button.with_label (_("Cancel"));
            rec_cancel.tooltip_text = _ ("Cancel the recording without saving the file");
            rec_cancel.clicked.connect (() => { this.destroy (); });

            var img_continue = new Gtk.Image.from_icon_name ("media-record", Gtk.IconSize.DIALOG);
            var rec_continue = new Gtk.Button.with_label (_("Continue"));
            rec_continue.tooltip_text = _ ("Continue recording");
            rec_continue.clicked.connect (toggle_recording);

            var img_finish = new Gtk.Image.from_icon_name ("document-save", Gtk.IconSize.DIALOG);
            rec_finish = new Gtk.Button.with_label (_("Finish"));
            rec_finish.tooltip_text = _ ("Stop the recording and save the file");
            rec_finish.clicked.connect (stop_recording);
            rec_finish.get_style_context ().add_class ("suggested-action");

            recording_controls.attach (img_cancel, 0, 0);
            recording_controls.attach (rec_cancel, 0, 1);
            recording_controls.attach (img_continue, 1, 0);
            recording_controls.attach (rec_continue, 1, 1);
            recording_controls.attach (img_finish, 2, 0);
            recording_controls.attach (rec_finish, 2, 1);

            content.add (tabs);
            content.add (recording_controls);

            var start_bt = new Gtk.Button.with_label (_ ("Start Recording"));
            start_bt.can_default = true;
            start_bt.get_style_context ().add_class ("suggested-action");
            start_bt.clicked.connect (toggle_recording);

            var cancel_bt = new Gtk.Button.with_label (_ ("Close"));
            cancel_bt.clicked.connect (() => { this.destroy (); });

            Gtk.Box actions = this.get_action_area () as Gtk.Box;
            actions.halign = Gtk.Align.CENTER;
            actions.margin_top = 12;
            actions.add (cancel_bt);
            actions.add (start_bt);

            create_indicator ();

            this.show_all ();
            this.set_default (start_bt);

            recording_controls.hide ();

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
                    } else {
                        selectionarea.destroy ();
                        settings.monitor = int.parse (monitors_combo.active_id);
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

            this.destroy.connect (
                () => {
                    if (recording) {
                        stop_recording ();
                    }
                    if (selectionarea != null) {
                        selectionarea.destroy ();
                    }
                });
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
                pipeline.set_state (Gst.State.NULL);

                this.recording = false;

                save_file ();
                pipeline.dispose ();
                pipeline = null;
                break;
            default :
                break;
            }

            return true;
        }

        private bool save_file () {
            var dialog = new Gtk.FileChooserDialog (_ ("Save Screencast"), this, Gtk.FileChooserAction.SAVE, _ ("Save"), Gtk.ResponseType.OK);

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
            stop_item.tooltip_text = _ ("Stop the recording and save the file");
            stop_item.activate.connect (
                () => {
                    stop_recording ();
                });
            menu.append (stop_item);

            menu.append (new Gtk.SeparatorMenuItem ());

            var quit_item = new Gtk.MenuItem.with_label (_ ("Cancel"));
            quit_item.tooltip_text = _ ("Cancel the recording without saving the file");
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

        private void show_recording_view () {
            recording_controls.show ();
            tabs.hide ();
            stack_switcher.hide ();
            this.get_action_area ().hide ();
            rec_finish.grab_focus ();
        }

        private void show_default_view () {
            recording_controls.hide ();
            tabs.show ();
            stack_switcher.show ();
            this.get_action_area ().show ();
        }

        private void set_indicator_icon (string icon) {
            indicator.set_icon_full (icon, icon);;
        }

        private void start_cowndown () {
            var count = new Screencast.Widgets.Countdown ();
            count.start ();
            this.opacity = 0;
        }

        public void pause_recording () {
            pipeline.set_state (Gst.State.PAUSED);
            this.recording = false;
            set_indicator_icon ("media-playback-pause-symbolic");
            toggle_item.label = _ ("Continue");
            if (keyview != null && settings.mouse_circle) {
                if (settings.mouse_circle) {
                    keyview.circle.hide ();
                }
            }

            show_recording_view ();
            this.opacity = 1;
            this.present ();
        }

        public void stop_recording () {
            keyview.destroy ();
            keyview = null;
            this.present ();
            if (!this.recording) {
                debug ("resuming recording");
                this.pipeline.set_state (Gst.State.PLAYING);
                this.recording = true;
            }
            pipeline.send_event (new Gst.Event.eos ());
            set_indicator_icon ("media-playback-stop-symbolic");
            show_default_view ();
            this.opacity = 1;
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
            this.opacity = 0;
            this.pipeline.set_state (Gst.State.PLAYING);
            this.recording = true;

            set_indicator_icon ("media-record-symbolic");
            toggle_item.label = _ ("Pause");

            if (settings.keyview || settings.clickview || settings.mouse_circle) {;
                if (settings.mouse_circle) {
                    keyview.circle.show ();
                }
            }
        }

        public void start_recording () {
            if (settings.keyview || settings.clickview || settings.mouse_circle) {
                Gdk.RGBA circle = { 0, 0, 0, 0};
                circle.parse (settings.mouse_circle_color);
                keyview = new Screencast.Widgets.KeyView (settings.keyview, settings.clickview, settings.mouse_circle, circle);
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

            string cores = "0-1";

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

            recording = true;

            set_indicator_icon ("media-record-symbolic");
            toggle_item.label = _ ("Pause");
        }
    }
}
