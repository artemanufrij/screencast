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

namespace Eidete {
    class LLabel : Gtk.Label {
        public LLabel (string label) {
            this.set_halign (Gtk.Align.START);
            this.label = label;
        }

        public LLabel.indent (string label) {
            this (label);
            this.margin_left = 10;
        }

        public LLabel.markup (string label) {
            this (label);
            this.use_markup = true;
        }

        public LLabel.right (string label) {
            this.set_halign (Gtk.Align.END);
            this.label = label;
        }

        public LLabel.right_with_markup (string label) {
            this.set_halign (Gtk.Align.END);
            this.use_markup = true;
            this.label = label;
        }
    }

    public struct Settings {
        public int sx;
        public int sy;
        public int ex;
        public int ey;
        public int monitor;
        public bool audio;
        public bool keyview;
        public bool clickview;
        public bool mouse_circle;
        public Gdk.RGBA mouse_circle_color;
        public string destination;
    }

    public class EideteApp : Granite.Application {
        construct {
            program_name = "Screencast";
            exec_name = "com.github.artemanufrij.screencast";
            application_id = exec_name;
            app_launcher = application_id + ".desktop";
        }

        public dynamic Gst.Pipeline pipeline;

        public Gtk.Window main_window;
        public Eidete.Widgets.KeyView keyview;
        public Eidete.Widgets.SelectionArea selectionarea;
        private Gtk.Stack tabs;
        private Gtk.Grid pause_grid;
        private Gtk.Grid main_box;
        private Gtk.Box home_buttons;
        private Gtk.StackSwitcher stack_switcher;
        public Wnck.Window win;
        public Gdk.Screen screen;
        public Gdk.Rectangle monitor_rec;

        public Settings settings;

        public bool recording;
        public bool typing_size;

        public Gst.Bin videobin;
        public Gst.Bin audiobin;

        public EideteApp () {
        }

        public void start_and_build () {
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;

            this.screen = Gdk.Screen.get_default ();
            this.main_window = new Gtk.Window ();
            this.main_window.icon_name = exec_name;
            this.main_window.set_application (this);
            this.main_window.window_position = Gtk.WindowPosition.CENTER;
            this.main_window.set_resizable (false);

            /* Use CSD */
            var header = new Gtk.HeaderBar ();
            header.title = program_name;
            header.set_show_close_button (true);
            header.get_style_context ().remove_class ("header-bar");

            this.main_window.set_titlebar (header);

            if (!this.main_window.is_composited ()) {
                warning ("Compositing is not supported. No transparency available.");
            }

            /*
              UI
            */

            tabs = new Gtk.Stack ();

            var grid = new Gtk.Grid ();
            grid.column_spacing = 12;
            grid.row_spacing = 6;
            grid.hexpand = false;

            var monitors_combo = new Gtk.ComboBoxText ();
            monitors_combo.hexpand = true;

            for (var i = 0; i < screen.get_n_monitors (); i++) {
                // TODO proper translation here
                monitors_combo.append (i.to_string (), _("Monitor") + " " + (i + 1).to_string ());
            }

            monitors_combo.active = 0;

            if (screen.get_n_monitors () == 1)
                monitors_combo.set_sensitive (false);

            var primary = screen.get_primary_monitor ();
            var scale = screen.get_monitor_scale_factor (primary);
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

            var recordingarea_combo = new Gtk.ComboBoxText ();
            recordingarea_combo.append ("full", _("Fullscreen"));
            recordingarea_combo.append ("custom", _("Custom"));
            recordingarea_combo.active = 0;

            var use_comp_sounds = new Gtk.CheckButton ();
            use_comp_sounds.halign = Gtk.Align.START;
            use_comp_sounds.set_sensitive (false);

            var use_audio = new Gtk.CheckButton ();
            use_audio.halign =Gtk. Align.START;

            var audio_source = new Gtk.ComboBoxText ();
            audio_source.append ("0", _("Default"));
            audio_source.active = 0;
            audio_source.hexpand = true;
            audio_source.set_sensitive (false);

            var audio_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            audio_box.pack_start (use_audio, false, true, 0);
            audio_box.pack_start (audio_source, true, true, 0);

            var sound = new LLabel.markup ("<b>" + _("Sound") + "</b>");
            sound.margin_top = 18;

            var video = new LLabel.markup ("<b>" + _("Video") + "</b>");
            video.margin_top = 12;

            var keyboard = new LLabel.markup ("<b>" + _("Keyboard") + "</b>");
            keyboard.margin_top = 18;

            var mouse = new LLabel.markup ("<b>" + _("Mouse") + "</b>");
            mouse.margin_top = 12;

            grid.attach (sound, 0, 0, 1, 1);
            grid.attach (new LLabel.right (_("Record Computer Sounds:")), 0, 1, 1, 1);
            grid.attach (use_comp_sounds, 1, 1, 1, 1);
            grid.attach (new LLabel.right (_("Record from Microphone:")), 0, 2, 1, 1);
            grid.attach (audio_box, 1, 2, 1, 1);
            grid.attach ((video), 0, 3, 2, 1);
            grid.attach (new LLabel.right (_("Record from Monitor:")), 0, 4, 1, 1);
            grid.attach (monitors_combo, 1, 4, 1, 1);
            grid.attach (new LLabel.right (_("Recording Area:")), 0, 5, 1, 1);
            grid.attach (recordingarea_combo, 1, 5, 1, 1);
            grid.attach (new LLabel.right (_("Width:")), 0, 6, 1, 1);
            grid.attach (width, 1, 6, 1, 1);
            grid.attach (new LLabel.right (_("Height:")), 0, 7, 1, 1);
            grid.attach (height, 1, 7, 1, 1);

            // grid2
            var grid2 = new Gtk.Grid ();

            var use_keyview = new Gtk.CheckButton ();
            use_keyview.halign = Gtk.Align.START;

            var use_clickview = new Gtk.CheckButton ();
            use_clickview.halign = Gtk.Align.START;

            var use_circle = new Gtk.CheckButton ();
            use_circle.halign = Gtk.Align.START;

            var circle_color = new Gtk.ColorButton ();

            var circle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            circle_box.pack_start (use_circle, false);
            circle_box.pack_start (circle_color);

            grid2.attach ((keyboard), 0, 0, 1, 1);
            grid2.attach (new LLabel.right (_("Pressed keys on screen:")), 0, 1, 1, 1);
            grid2.attach (use_keyview, 1, 1, 1, 1);
            grid2.attach ((mouse), 0, 2, 1, 1);
            grid2.attach (new LLabel.right (_("Mouse clicks on screen:")), 0, 3, 1, 1);
            grid2.attach (use_clickview, 1, 3, 1, 1);
            grid2.attach (new LLabel.right (_("Circle around the cursor:")), 0, 4, 1, 1);
            grid2.attach (circle_box, 1, 4, 1, 1);
            grid2.column_spacing = 12;
            grid2.row_spacing = 6;
            grid2.hexpand = true;

            tabs.add_titled (grid, "behavior", _("Behavior"));
            tabs.add_titled (grid2, "apperance", _("Appearance"));

            main_box = new Gtk.Grid ();
            stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.stack = tabs;
            stack_switcher.halign = Gtk.Align.CENTER;
            build_pause_ui ();
            pause_grid.show_all();
            pause_grid.hide();
            pause_grid.no_show_all = true;
            main_box.attach (stack_switcher, 0, 0, 1, 1);
            main_box.attach (tabs, 0, 1, 1, 1);
            main_box.attach (pause_grid, 0, 2, 1, 1);

            var start_bt = new Gtk.Button.with_label (_("Start Recording"));
            start_bt.can_default = true;
            start_bt.get_style_context ().add_class ("noundo");
            start_bt.get_style_context ().add_class ("suggested-action");

            var cancel_bt = new Gtk.Button.with_label (_("Cancel"));

            home_buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
            home_buttons.homogeneous = true;
            home_buttons.pack_start (cancel_bt, false, true, 0);
            home_buttons.pack_end (start_bt, false, true, 0);
            home_buttons.margin_top = 24;

            main_box.attach (home_buttons, 0, 3, 1, 1);
            main_box.margin = 12;

            this.main_window.add (main_box);

            this.main_window.show_all ();
            this.main_window.set_default (start_bt);
            this.main_window.present ();

            /*
              Events
            */

            cancel_bt.clicked.connect (() => {
                this.main_window.destroy ();
            });

            start_bt.clicked.connect (() => {
                var count = new Eidete.Widgets.Countdown ();
                this.main_window.iconify ();
                count.start (this);
            });

            settings.monitor = 0;
            monitors_combo.changed.connect (() => {
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

            settings.sx = this.monitor_rec.x * scale;
            settings.sy = this.monitor_rec.y * scale;
            settings.ex = settings.sx + this.monitor_rec.width * scale - 1;
            settings.ey = settings.sy + this.monitor_rec.height * scale - 1;

            recordingarea_combo.changed.connect (() => {
                if (recordingarea_combo.active_id != "full"){
                    selectionarea = new Eidete.Widgets.SelectionArea ();
                    selectionarea.show_all ();
                    width.set_sensitive (true);
                    height.set_sensitive (true);
                    selectionarea.geometry_changed.connect ((x, y, w, h) => {
                        if (!typing_size){
                            width.value  = (int) w;
                            height.value = (int) h;
                            settings.sx = x;
                            settings.sy = y;
                            settings.ex = settings.sx + w - 1;
                            settings.ey = settings.sy + h - 1;
                        }
                    });

                    selectionarea.focus_in_event.connect ((ev) => {
                        if (this.recording){
                            this.main_window.deiconify ();
                            this.main_window.present ();
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

                    width.set_sensitive (false);
                    height.set_sensitive (false);
                }
            });

            width.key_release_event.connect ((e) => {
                selectionarea.resize ((int) width.value, (int) height.value);
                typing_size = true;

                return false;
            });

            width.focus_out_event.connect ((e) => {
                typing_size = false;

                return false;
            });

            height.key_release_event.connect ((e) => {
                selectionarea.resize ((int) width.value, (int) height.value);
                typing_size = true;

                return false;
            });

            height.focus_out_event.connect ((e) => {
                typing_size = false;

                return false;
            });

            settings.audio = false;
            use_audio.toggled.connect (() => {
                settings.audio = use_audio.active;
                audio_source.set_sensitive (use_audio.active);
            });

            Gdk.Screen.get_default ().monitors_changed.connect (() => {
                if (Gdk.Screen.get_default ().get_n_monitors () > 1)
                    monitors_combo.set_sensitive (true);
                else
                    monitors_combo.set_sensitive (false);
            });

            settings.keyview = false;
            use_keyview.toggled.connect (() => {
                settings.keyview = use_keyview.active;
            });

            settings.clickview = false;
            use_clickview.toggled.connect (() => {
                settings.clickview = use_clickview.active;
            });

            settings.mouse_circle = false;
            use_circle.toggled.connect (() => {
                settings.mouse_circle = use_circle.active;
            });

            settings.mouse_circle_color = { 1, 1, 0, 0.3 };
            circle_color.use_alpha = true;
            circle_color.rgba = settings.mouse_circle_color;
            circle_color.color_set.connect (() => {
                settings.mouse_circle_color = circle_color.rgba;
            });

            settings.destination = GLib.Environment.get_tmp_dir () +
                    "/screencast" + new GLib.DateTime.now_local ().to_unix ().to_string () + ".webm";

            ulong handle = 0;
            handle = Wnck.Screen.get_default ().active_window_changed.connect (() => {
                this.win = Wnck.Screen.get_default ().get_active_window ();
                this.win.state_changed.connect ((changed_s, new_s) => {
                    if (recording && (new_s == 0)) {
                        pipeline.set_state (Gst.State.PAUSED);
                        this.recording = false;
                        switch_to_paused (true);
                    }
                });

                Wnck.Screen.get_default ().disconnect (handle);
            });

            this.main_window.focus_in_event.connect ((ev) => {
                if (this.selectionarea != null && !this.selectionarea.not_visible) {
                    this.selectionarea.present ();
                    this.main_window.present ();
                }

                return false;
            });

/* disabled for now until mutter supports it better
            this.main_window.visibility_notify_event.connect ((ev) => {
                if (this.recording && ev.state == 0){
                    debug ("pausing recording");

                    pipeline.set_state (State.PAUSED);
                    this.recording = false;
                    switch_to_paused (true);
                }

                return false;
            });
*/

            this.main_window.destroy.connect (() => {
                if (recording) {
                    finish_recording ();
                }
            });

            Granite.Services.Logger.initialize ("Eidete");
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

            uint major;
            uint minor;
            uint micro;
            uint nano;

            Gst.version (out major, out minor, out micro, out nano);

            message ("GStreamer version  : %u.%u.%u.%u", major, minor, micro, nano);
            message ("Gtk build version  : %u.%u.%u", Gtk.MAJOR_VERSION, Gtk.MINOR_VERSION, Gtk.MICRO_VERSION);
            message ("Gtk runtime version: %u.%u.%u", Gtk.get_major_version (), Gtk.get_minor_version (), Gtk.get_micro_version ());
        }

        public override void activate () {
            if (this.get_windows ().length () == 0) {
                this.start_and_build ();
            } else {
                if (pause_rec)
                    this.main_window.present ();
                else if (finish_rec)
                    finish_recording ();
            }
        }

        private void build_pause_ui () {
            pause_grid = new Gtk.Grid ();
            // this.main_window.title = _("Recording paused");

            var img_text_grid = new Gtk.Grid ();
            var text_grid = new Gtk.Grid ();

            var title = new LLabel.markup ("<span weight='bold' size='larger'>" + _("Recording paused") + "</span>");
            title.valign = Gtk.Align.START;

            var info = new LLabel (_("You can continue or finish the recording now"));
            info.valign = Gtk.Align.START;
            info.margin_top = 6;

            var buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            buttons.homogeneous = true;
            buttons.spacing = 6;
            buttons.margin_top = 24;

            var continue_bt = new Gtk.Button.with_label (_("Continue"));
            continue_bt.set_tooltip_text (_("Continue recording"));

            var stop_bt = new Gtk.Button.with_label (_("Finish"));
            stop_bt.set_tooltip_text (_("Stop the recording and save the file"));
            stop_bt.get_style_context ().add_class ("suggested-action");

            var cancel_bt = new Gtk.Button.with_label (_("Cancel"));
            cancel_bt.set_tooltip_text (_("Cancel the recording without saving the file"));

            buttons.pack_end (stop_bt, false, true, 0);
            buttons.pack_end (continue_bt, false, true, 0);
            buttons.pack_end (cancel_bt, false, true, 0);

            var img = new Gtk.Image.from_icon_name ("media-playback-pause", Gtk.IconSize.DIALOG);
            img.valign = Gtk.Align.START;
            img.margin_right = 12;

            text_grid.attach (title, 0, 0, 1, 1);
            text_grid.attach (info, 0, 1, 1, 1);

            img_text_grid.attach (img, 0, 0, 1, 1);
            img_text_grid.attach (text_grid, 1, 0, 1, 1);

            pause_grid.attach (img_text_grid, 0, 0, 1, 1);
            pause_grid.attach (buttons, 0, 2, 1, 1);

            stop_bt.can_default = true;
            this.main_window.set_default (stop_bt);

            /*
              Events
            */

            cancel_bt.clicked.connect (() => {
                this.main_window.destroy ();
            });

            stop_bt.clicked.connect (() => {
                finish_recording ();
            });

            continue_bt.clicked.connect (() => {
                this.main_window.iconify ();
                this.pipeline.set_state (Gst.State.PLAYING);
                this.recording = true;

                switch_to_paused (false);
            });
        }

        public void record () {
            if (settings.keyview || settings.clickview || settings.mouse_circle) {
                keyview = new Eidete.Widgets.KeyView (settings.keyview, settings.clickview,
                    settings.mouse_circle, settings.mouse_circle_color);
                keyview.focus_in_event.connect ((ev) => {
                    if (this.recording) {
                        this.main_window.deiconify ();
                        this.main_window.present ();
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

                videobin = (Gst.Bin) Gst.parse_bin_from_description (
                            "ximagesrc name=\"videosrc\" ! video/x-raw, framerate=24/1 ! videoconvert ! vp8enc name=\"encoder\" ! queue", true);
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }

            // audio bin
            this.audiobin = new Gst.Bin ("audio");

            try {
                audiobin = (Gst.Bin) Gst.parse_bin_from_description ("pulsesrc name=\"audiosrc\" !
                        audioconvert ! audioresample ! audiorate ! vorbisenc ! queue", true);
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
            sink.set ("location", settings.destination);

            var src = videobin.get_by_name ("videosrc");

            assert (src != null);

            src.set ("startx", this.settings.sx);
            src.set ("starty", this.settings.sy);
            src.set ("endx",   this.settings.ex);
            src.set ("endy",   this.settings.ey);
            src.set ("use-damage", false);
            src.set ("screen-num", this.settings.monitor);

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

            if (settings.audio)
                pipeline.add_many (audiobin, videobin, muxer, sink);
            else
                pipeline.add_many (videobin, muxer, sink);

            var video_pad = videobin.get_static_pad ("src");

            assert (video_pad != null);

            var m = muxer.get_request_pad ("video_%u");

            assert (m != null);

            video_pad.link (m);

            if (settings.audio) {
                audiobin.get_static_pad ("src").link (muxer.get_request_pad ("audio_%u"));
            }

            muxer.link (sink);

            pipeline.get_bus ().add_watch (Priority.DEFAULT, bus_message_cb);

            pipeline.set_state (Gst.State.READY);

            if (selectionarea != null)
                selectionarea.to_discrete ();

            pipeline.set_state (Gst.State.PLAYING);
            this.recording = true;
        }

        public void finish_recording () {
            if (!this.recording) {
                debug ("resuming recording\n");

                this.pipeline.set_state(Gst.State.PLAYING);
                this.recording = true;
            }

            pipeline.send_event (new Gst.Event.eos ());
        }

        private bool bus_message_cb (Gst.Bus bus, Gst.Message msg) {
            switch (msg.type) {
                case Gst.MessageType.ERROR:
                    GLib.Error err;

                    string debug;

                    msg.parse_error (out err, out debug);

                    display_error ("Eidete encountered a gstreamer error while recording, creating a screencast is not possible:\n%s\n\n[%s]"
                        .printf (err.message, debug), true);
                    stderr.printf ("Error: %s\n", debug);
                    pipeline.set_state (Gst.State.NULL);

                    break;
                case Gst.MessageType.EOS:
                    debug ("received EOS\n");

                    pipeline.set_state (Gst.State.NULL);

                    this.recording = false;

                    var end = new Eidete.Widgets.EndDialog (this);
                    end.display ();
                    this.main_window.destroy ();

                    break;
                default:
                    break;
            }

            return true;
        }

        // only visuals
        public void switch_to_paused (bool to_normal) {
            if (to_normal) {
                this.main_window.title = _("Recording paused");

                tabs.hide ();
                stack_switcher.hide ();
                home_buttons.hide ();
                pause_grid.show ();

                this.main_window.icon_name = "eidete";
                this.app_icon = "eidete";
            } else {
                this.main_window.title = _("Pause recording");

                if (tabs.visible) {
                    tabs.hide ();
                    stack_switcher.hide ();
                    home_buttons.hide ();
                    pause_grid.show ();
                }

                this.main_window.icon_name = "media-playback-pause";
                this.app_icon = "media-playback-pause";
            }
        }

        /**
         * Displays an error dialog with the given message to the user
         *
         * @param error The message to display
         * @param fatal Quit eidete after the user dismissed the dialog
         */
        private void display_error (string error, bool fatal) {
            var dialog = new Gtk.MessageDialog (main_window, Gtk.DialogFlags.MODAL,
                    Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, error);
            dialog.show_all ();
            dialog.response.connect (() => {
                dialog.destroy ();

                if (fatal)
                    main_window.destroy ();
            });
            dialog.run ();
        }
    }
}

Eidete.EideteApp eidete;

bool pause_rec;
bool finish_rec;

const OptionEntry[] entries = {
    { "pause", 'n', 0, OptionArg.NONE, ref pause_rec, N_("Pause Recording"), "" },
    { "finish", 'n', 0, OptionArg.NONE, ref finish_rec, N_("Finish Recording"), "" },
    { null }
};

public static int main (string [] args) {
    var context = new OptionContext ("ctx");
    context.add_main_entries (entries, "eidete");
    context.add_group (Gtk.get_option_group (true));

    try {
        context.parse (ref args);
    } catch (Error e) {
        error ("Error: " + e.message);
    }

    Gst.init (ref args);

    eidete = new Eidete.EideteApp ();

    return eidete.run (args);
}
