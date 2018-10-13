#!/usr/bin/perl -w

use strict;
use warnings;
use Image::Magick;
use File::Copy;
use Getopt::Long;

my %opt = ();
GetOptions (\%opt,
	    'screen|s=s',
	    'root|r=s');

unless ($opt{screen} == 1 || $opt{screen} == 2) { die "Only works for 2 screens, for now, lets say."; }

unless ($opt{root}) { die  "Must supply a root directory containing a 'pictures' subdir"; }

unless (-d $opt{root}."/pictures") { die  "Must supply a root directory containing a 'pictures' subdir"; }

### Start CONFIG

my $temp = "$opt{root}/temp$opt{screen}";
my $searchPath = '$opt{root}/pictures/';
my $final = "$opt{root}/background/$opt{screen}/bgotd";
my $black = '$opt{root}/background/.black.bgotd.jpg';
my $switchTime = 600;            # time in seconds
my $maxW = 1920;
my $maxH = 1200;
my $maxDimensions = "$maxW"."x"."$maxH";  # What's the max size of the photo.
                                    # They will be resized to this dimension
				    # if needed (lets two different sized
				    # pictures be placed side by side without funny blank space.
my $halfDim = $maxW/2 ."x"."$maxH";

### END CONFIG

# bgotd-more -- background of the day (more)
#
# A pretty simple script which randomly picks a jpg/JPG/jpeg/JPEG photo to place as your
# Gnome desktop. If the photo is taller than it is wide, it finds another
# taller-than-wide photo and puts them side by side with Imagemagick
#
# Written by Michael Moore, Nov. 2007
# This work is hereby placed in the public domain


my $photoa = "";
my $photob = "";

while(1)
{

  my @photos = `find $searchPath -type f | grep [jJ][pP][eE]*[gG]`;
  chomp(@photos);

  system("ps aux |grep x11vnc |grep -v grep -q");
  unless ($?) { # x11vnc is running, set screen to black.
    #this is for kde:
    `cp $black $final.jpg`;
    `cp $black ${final}_1.jpg`;
#this is for mate 1.6:
#      `gsettings set org.mate.background picture-filename ""`;
#      `gsettings set org.mate.background color-shading-type solid`;
#      `gsettings set org.mate.background primary-color #000000`;
#      `gsettings set org.mate.background secondary-color #000000`;
#this is for mate 1.4:
#     `mateconftool-2 --type string --set /desktop/mate/background/picture_options none`;
#This is for gnome3
#    `gsettings set org.gnome.desktop.background picture-options none`;
    sleep 3000; next;
  }

  #For Gnome, use this
#  my $ss = `gnome-screensaver-command -q`;
#  unless ($ss =~ /inactive/) { sleep 600; next; }

#for mate, use this
#  my $ss = `mate-screensaver-command -q`;
#  unless ($ss =~ /inactive/) { sleep 600; next; }

  #for kde, use this
  system("ps aux |grep kblankscrn |grep -v grep -q");
  unless ($?) { # screensaver is running, don't set?
    sleep 600; next; }

#For XFCE use this
#  my $ss = `xscreensaver-command -time`;
#  unless ($ss =~ /non-blanked/) { sleep 600; next; }


  $photoa = $photos[int(rand($#photos+1))];
  my $pa = new Image::Magick;
  $pa->Read($photoa);
  my ($ha,$wa) = $pa->Get('height','width');

  my $color_cmd = 'convert '.$temp.'/temp.jpg -scale 1x1\! -format \'%[fx:int(255*r)],%[fx:int(255*g)],%[fx:int(255*b)]\' info:-';
  #Lets stick 2 pics together
  #    if ($wa/$ha < 2) {
  if(0) {
    copy $photoa, $temp."/bgotda.jpg";
    copy $photoa, $temp."/temp.jpg";
    # maybe someday I'll do this... or use a different image package... "Imager" maybe?
    # $pa->Scale(geometry=>'1x1');
    # my @hist = $pa->Histogram();
    # my color = $pa->Get('Pixel[0,0]');
    my $color=`$color_cmd`;
    chomp $color;
    $color = 'rgb\(' . $color . '\)';
    `mogrify -resize $halfDim -extent $halfDim -gravity center -background $color $temp/bgotda.jpg`;
    
    my $hb;
    my $wb;
    do {
      $photob = $photos[int(rand($#photos+1))];
      my $pb = new Image::Magick;
      $pb->Read($photob);
      ($hb,$wb) = $pb->Get('height','width');
    } while($wb/$hb > 2);

    copy $photob, $temp."/bgotdb.jpg";
    copy $photob, $temp."/temp.jpg";
    $color=`$color_cmd`;
    chomp $color;
    $color = 'rgb\(' . $color . '\)';
    `mogrify -resize $halfDim -extent $halfDim -gravity center -background $color $temp/bgotdb.jpg`;
    `montage $temp/bgotda.jpg $temp/bgotdb.jpg -geometry $halfDim $temp/bgotd.jpg`;
  }
  #lets do it with a single picture..
  else {
    copy $photoa, $temp."/bgotd.jpg";
    copy $photoa, $temp."/temp.jpg";
    my $color=`$color_cmd`;
    chomp $color;
    $color = 'rgb\(' . $color . '\)';
    `mogrify -resize $maxDimensions -extent $maxDimensions -gravity center -background $color $temp/bgotd.jpg`;
  }

  copy $temp."/bgotd.jpg", $final.".jpg";
  copy $temp."/bgotd.jpg", $final."_1.jpg";

  #for gnome use this
  #    `gconftool-2 --type string --set /desktop/gnome/background/picture_filename $final`;
  #for mate 1.4 use this
  #    `mateconftool-2 --type string --set /desktop/mate/background/picture_filename $final`;
  #    `mateconftool-2 --type string --set /desktop/mate/background/picture_options spanned`;

  #for mate 1.6 use this
  # `gsettings set org.mate.background picture-filename $final`;
  # `gsettings set org.mate.background picture-options spanned`;

  #for gnome 3 use this:
  #  `gsettings set org.gnome.desktop.background picture-uri file:///$final`;
  #  `gsettings set org.gnome.desktop.background picture-options spanned`;

  #for xfce, in settings editor, add to xfce4-desktop
  # /backdrop->screen0->xinerama-stretch  BOOL True
  # Then edit image path for screen 0 to be ~/.bgotd.jpg
  #then use this:
  #    `killall xfdesktop`;

  #for kde, set up file path to be the same as $final, then just update the file.
  #this is already done above.

  #for awesomewm I have a function that sets the screens now that the files are in the "right" place .. this is all terrible and hard-coded, but you know, life...
  system('echo "wallpaper()"|/usr/bin/awesome-client');
  sleep($switchTime);
}
