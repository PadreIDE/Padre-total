package Padre::Plugin::Catalyst::Panel;

use strict;
use warnings;

our $VERSION = '0.06';

use Padre::Wx ();
use Padre::Util ('_T');
use Wx ();
use base 'Wx::Panel';

sub new {
	my $class      = shift;
	my $main       = shift;
	my $self       = $class->SUPER::new( Padre::Current->main->bottom );

    require Scalar::Util;;
	$self->{main} = $main;
	Scalar::Util::weaken($self->{main});

    # main container
	my $box        = Wx::BoxSizer->new(Wx::wxVERTICAL);
	
	# top box, holding buttons, icons and checkboxes
	
	#TODO FIXME: the top bar is too big, it would be nice to
	# make it fit just the size of the button, and vertically align
	# the other controls do centralize them (vertically).
	# Maybe we need a Wx::GridSizer
	my $top_box    = Wx::BoxSizer->new(Wx::wxHORIZONTAL);

	# visual led showing server state	
	my $led = Wx::StaticBitmap->new( $self, -1, Wx::wxNullBitmap );
	$led->SetBitmap( $self->led('red') );
	$top_box->Add( $led );
    $self->{led} = $led;
	
	# button to toggle server
	my $button = Wx::Button->new( $self, -1, _T('Start Server') );
	#Wx::Event::EVT_BUTTON( $self, $button, \&Padre::Plugin::Catalyst::toggle_server );
	Wx::Event::EVT_BUTTON( $self, $button, 
        sub {
            my $panel = shift;
            if ( $panel->{button}->GetLabel eq _T('Start Server') ) {
                $panel->{main}->on_start_server;
            }
            else {
                $panel->{main}->on_stop_server;
            }
        },
    );
	$top_box->Add($button);
	
	# checkbox to auto-restart
	my $checkbox = Wx::CheckBox->new($self, -1, _T('auto-restart'));
	Wx::Event::EVT_CHECKBOX( $self, $checkbox, sub { shift->{config}->{auto_restart} ^= 1 } );
	$top_box->Add( $checkbox );
	
	# finishing up the top_box
	$box->Add( $top_box, 1, Wx::wxGROW );

    # output panel for server
    require Padre::Wx::Output;
    my $output = Padre::Wx::Output->new($self);
	$box->Add( $output, 2, Wx::wxGROW );

    # wrapping it up and showing on the screen
	$self->SetSizer($box);
	Padre::Current->main->bottom->show($self);
	
	# holding on to some objects we'll need to manipulate later on
	$self->{output}   = $output;
	$self->{button}   = $button;
	$self->{checkbox} = $checkbox;

    return $self;
}

sub output { return shift->{output} }

sub gettext_label {	return _T('Catalyst Dev Server') }

sub toggle_panel {
    my ($self, $enable) = (@_);
    
    my $new_label = [ _T('Stop Server'), _T('Start Server') ];
    
    $self->{checkbox}->Enable($enable);
    $self->{button}->SetLabel( $new_label->[$enable] );
    
    $self->{led}->SetBitmap( $self->led( $enable == 1 ? 'red' : 'green' ) );
}

# dirty hack to allow seamless use of Padre::Wx::Output
sub bottom { return $_[0] }

# and now some xpm icons for the server leds
sub led {
    my ($self, $color) = (@_);

    my $led = {
        red => [
'28 28 274 2' , '  	c None'   , '. 	c #CC8F8F', '+ 	c #A07676', '@ 	c #D97979', '# 	c #EF8484',
'$ 	c #F68686', '% 	c #EE7878', '& 	c #D86565', '* 	c #AE5858', '= 	c #6D5E5E', '- 	c #CC9696',
'; 	c #D59696', '> 	c #F6A4A4', ', 	c #FCA6A6', '\' 	c #FFA5A5', ') 	c #FFA1A1', '! 	c #FF9A9A',
'~ 	c #FF9191', '{ 	c #FF8585', '] 	c #FF7878', '^ 	c #FA6C6C', '/ 	c #E25A5A', '( 	c #7D5A5A',
'_ 	c #C48787', ': 	c #F5A9A9', '< 	c #FCB1B1', '[ 	c #FFB8B8', '} 	c #FFBBBB', '| 	c #FFBABA',
'1 	c #FFB6B6', '2 	c #FFAEAE', '3 	c #FFA3A3', '4 	c #FF9696', '5 	c #FF8787', '6 	c #FF6969',
'7 	c #F95B5B', '8 	c #C74D4D', '9 	c #5E5959', '0 	c #DF9B9B', 'a 	c #FCABAB', 'b 	c #FFB9B9',
'c 	c #FFC4C4', 'd 	c #FFCCCC', 'e 	c #FFCFCF', 'f 	c #FFCECE', 'g 	c #FFC9C9', 'h 	c #FFC0C0',
'i 	c #FFB4B4', 'j 	c #FFA6A6', 'k 	c #FF8484', 'l 	c #FF7373', 'm 	c #FF6363', 'n 	c #FF5353',
'o 	c #F04545', 'p 	c #645858', 'q 	c #DE9696', 'r 	c #FCA7A7', 's 	c #FFC8C8', 't 	c #FFD4D4',
'u 	c #FFDDDD', 'v 	c #FFE0E0', 'w 	c #FFDADA', 'x 	c #FFD1D1', 'y 	c #FFC3C3', 'z 	c #FFA2A2',
'A 	c #FF8F8F', 'B 	c #FF7D7D', 'C 	c #FF6B6B', 'D 	c #FF5A5A', 'E 	c #FF4A4A', 'F 	c #F03D3D',
'G 	c #5E5858', 'H 	c #C27E7E', 'I 	c #FC9E9E', 'J 	c #FFB1B1', 'K 	c #FFD5D5', 'L 	c #FFE1E1',
'M 	c #FFEAEA', 'N 	c #FFEEEE', 'O 	c #FFE8E8', 'P 	c #FFDEDE', 'Q 	c #FFD0D0', 'R 	c #FFBFBF', 
'S 	c #FFACAC', 'T 	c #FF9898', 'U 	c #FF7171', 'V 	c #FF5F5F', 'W 	c #FF4F4F', 'X 	c #FF4040', 
'Y 	c #D13838', 'Z 	c #585858', '` 	c #C88989', ' .	c #F69191', '..	c #FFA4A4', '+.	c #FFF4F4', 
'@.	c #FFF8F8', '#.	c #FFF7F7', '$.	c #FFF1F1', '%.	c #FFE6E6', '&.	c #FFD8D8', '*.	c #FFC6C6', 
'=.	c #FFB3B3', '-.	c #FF9E9E', ';.	c #FF8A8A', '>.	c #FF7676', ',.	c #FF5252', '\'.	c #FF4343', 
').	c #FF3636', '!.	c #854A4A', '~.	c #D18282', '{.	c #FC9292', '].	c #FFBCBC', '^.	c #FFEFEF', 
'/.	c #FFFDFD', '(.	c #FFFCFC', '_.	c #FFF6F6', ':.	c #FFEBEB', '<.	c #FFDCDC', '[.	c #FFCACA', 
'}.	c #FF8C8C', '|.	c #FF6565', '1.	c #FF5454', '2.	c #FF4444', '3.	c #FF3737', '4.	c #E83030', 
'5.	c #C57B7B', '6.	c #F87E7E', '7.	c #FF9090', '8.	c #FFFBFB', '9.	c #FFF5F5', '0.	c #FF2C2C', 
'a.	c #724F4F', 'b.	c #9D6868', 'c.	c #FC7A7A', 'd.	c #FF8D8D', 'e.	c #FFB7B7', 'f.	c #FFDBDB', 
'g.	c #FFF2F2', 'h.	c #FFF0F0', 'i.	c #FFE5E5', 'j.	c #FFD7D7', 'k.	c #FF2B2B', 'l.	c #AF3737', 
'm.	c #DC5656', 'n.	c #FF7474', 'o.	c #FF9B9B', 'p.	c #FFAFAF', 'q.	c #FFC2C2', 'r.	c #FFD2D2', 
's.	c #FFDFDF', 't.	c #FFE7E7', 'u.	c #FFECEC', 'v.	c #FFBEBE', 'w.	c #FF7272', 'x.	c #FF6060', 
'y.	c #FF5050', 'z.	c #FF4141', 'A.	c #FF3535', 'B.	c #FF2A2A', 'C.	c #FD1D1D', 'D.	c #F15A5A', 
'E.	c #FF6D6D', 'F.	c #FF7F7F', 'G.	c #FF9292', 'H.	c #FFC5C5', 'I.	c #FFD9D9', 'J.	c #FF6C6C', 
'K.	c #FF5B5B', 'L.	c #FF4C4C', 'M.	c #FF3E3E', 'N.	c #FF3232', 'O.	c #FF2828', 'P.	c #FE1E1E', 
'Q.	c #F95656', 'R.	c #FFA7A7', 'S.	c #FFB5B5', 'T.	c #FFCBCB', 'U.	c #FFC7C7', 'V.	c #FF6464', 
'W.	c #FF5555', 'X.	c #FF4747', 'Y.	c #FF3A3A', 'Z.	c #FF2F2F', '`.	c #FF2626', ' +	c #FF1E1E', 
'.+	c #F14B4B', '++	c #FF7A7A', '@+	c #FF8989', '#+	c #FF9797', '$+	c #FFADAD', '%+	c #FF8888', 
'&+	c #FF7979', '*+	c #FF6A6A', '=+	c #FF4D4D', '-+	c #FF2323', ';+	c #FE1A1A', '>+	c #DB4343', 
',+	c #FF5151', '\'+	c #FF8686', ')+	c #FFA0A0', '!+	c #FF9F9F', '~+	c #FF9999', '{+	c #FF4646', 
']+	c #FF3030', '^+	c #FF2727', '/+	c #FF1F1F', '(+	c #FD1616', '_+	c #B04343', ':+	c #FF7575', 
'<+	c #FF7E7E', '[+	c #FF8B8B', '}+	c #FF8E8E', '|+	c #FF4848', '1+	c #FF3434', '2+	c #FF1C1C', 
'3+	c #FB1212', '4+	c #6E5858', '5+	c #FB3F3F', '6+	c #FF7777', '7+	c #FF5C5C', '8+	c #FF4949', 
'9+	c #FF3F3F', '0+	c #FF2D2D', 'a+	c #FF1919', 'b+	c #734B4B', 'c+	c #E63838', 'd+	c #FF3D3D', 
'e+	c #FF4545', 'f+	c #FF6161', 'g+	c #FF6767', 'h+	c #FF4E4E', 'i+	c #FF2E2E', 'j+	c #FF2020', 
'k+	c #FF1B1B', 'l+	c #FE1414', 'm+	c #7E5252', 'n+	c #FB3434', 'o+	c #FF3B3B', 'p+	c #FF2121', 
'q+	c #FF1717', 'r+	c #8B4141', 's+	c #CB3636', 't+	c #FF4242', 'u+	c #FF3131', 'v+	c #FC1010', 
'w+	c #F12828', 'x+	c #FF3838', 'y+	c #FF3333', 'z+	c #FE1212', 'A+	c #5E5454', 'B+	c #645555', 
'C+	c #F02525', 'D+	c #FF2525', 'E+	c #FF2929', 'F+	c #FF1D1D', 'G+	c #FF1616', 'H+	c #675050', 
'I+	c #5E5656', 'J+	c #D22A2A', 'K+	c #FF2424', 'L+	c #FF2222', 'M+	c #FF1414', 'N+	c #FC0F0F', 
'O+	c #884545', 'P+	c #EB1F1F', 'Q+	c #FF1818', 'R+	c #FE1111', 'S+	c #8B4040', 'T+	c #734D4D', 
'U+	c #B03232', 'V+	c #FD1212', 'W+	c #FE1313', 'X+	c #FD1010', 'Y+	c #FB0E0E', '                                                        ', 
'                                                        ', 
'                  . + @ # $ % & * =                     ', 
'              - ; > , \' ) ! ~ { ] ^ / (                 ', 
'            _ : < [ } | 1 2 3 4 5 ] 6 7 8 9             ', 
'          0 a b c d e f g h i j 4 k l m n o p           ', 
'        q r b s t u v v w x y i z A B C D E F G         ', 
'      H I J c K L M N N O P Q R S T k U V W X Y Z       ', 
'    `  ...[ d u M +.@.#.$.%.&.*.=.-.;.>.m ,.\'.).!.      ', 
'    ~.{.j ].Q L ^.@./.(._.:.<.[.1 ) }.] |.1.2.3.4.Z     ', 
'  5.6.7.j } e v N #.(.8.9.M <.[.1 ) }.] |.1.2.3.0.a.    ', 
'  b.c.d.z e.[.f.O g._.9.h.i.j.*.=.-.;.>.m ,.\'.).k.l.Z   ', 
'  m.n.5 o.p.q.r.s.t.u.:.%.<.f v.S T { w.x.y.z.A.B.C.Z   ', 
'  D.E.F.G.\' 1 H.x I.u u &.e q.=.z 7.B J.K.L.M.N.O.P.Z   ', 
'  Q.|.>.5 T R.S.h s T.T.U.v.=.\' 4 { n.V.W.X.Y.Z.`. +Z   ', 
'  .+K.C ++@+#+..$+i [ e.i S z 4 %+&+*+K.=+z.A.k.-+;+Z   ', 
'  >+,+V J.++\'+~ ! )+3 3 !+~+7.\'+&+J.V ,.{+Y.]+^+/+(+Z   ', 
'  _+X.n V *+:+<+\'+[+}+}+[+\'+<+:+*+V 1.|+M.1+k.-+2+3+Z   ', 
'  4+5+|+,.K.V.J.l 6+++++6+l E.|.7+,.8+9+).0+`./+a+b+Z   ', 
'    c+d+e+=+W.K.f+|.g+g+|.f+7+W.h+{+M.).i+^+j+k+l+Z     ', 
'    m+n+Y.X X.L.y.1.W.W.1.,+=+X.z.o+1+0+^+p+2+q+r+Z     ', 
'      s+Z.A.Y.M.t+2.{+{+e+t+9+o+).u+k.`.p+2+q+v+Z       ', 
'      G w+k.Z.N.A.3.x+x+x+).y+]+0.O.-+/+k+q+z+A+Z       ', 
'        B+C+D+O.B.0.0+0+0.k.E+`.-+j+F+a+G+z+H+Z         ', 
'          I+J+j+p+-+-+K+-+L+j+ +2+a+q+M+N+A+Z           ',
'            Z O+P+k+2+2+k+k+a+Q+G+M+R+S+Z Z             ',
'                Z T+U+V+l+M+W+X+Y+b+Z Z                 ',
'                    Z Z Z Z Z Z Z Z                     ',
        ],
        green => [
'28 28 199 2', '  	c None', '. 	c #96C08A', '+ 	c #7B9873', '@ 	c #83C571', '# 	c #90D87D', 
'$ 	c #93DD7E', '% 	c #84D46F', '& 	c #72BF5E', '* 	c #629D52', '= 	c #5F6A5D', '- 	c #9BC291', 
'; 	c #9CC891', '> 	c #ABE49D', ', 	c #AEE99E', '\' 	c #AEEB9E', ') 	c #ABEA9B', '! 	c #A6E994', 
'~ 	c #9CE788', '{ 	c #93E47D', '] 	c #86E16E', '^ 	c #7BDA62', '/ 	c #6AC553', '( 	c #5E7658', 
'_ 	c #8EB882', ': 	c #B2E4A4', '< 	c #B8EBAA', '[ 	c #BFEFB2', '} 	c #C2F0B5', '| 	c #BDEFB0', 
'1 	c #B7EDA8', '2 	c #A2E88F', '3 	c #94E57E', '4 	c #7BDE61', '5 	c #6DD752', '6 	c #5AAE44', 
'7 	c #595D58', '8 	c #A2D096', '9 	c #B4EAA5', '0 	c #C0EFB4', 'a 	c #CAF2BF', 'b 	c #CFF3C6', 
'c 	c #D2F4C9', 'd 	c #CDF2C3', 'e 	c #C6F1BA', 'f 	c #BBEEAD', 'g 	c #91E47B', 'h 	c #83E16A', 
'i 	c #75DD5A', 'j 	c #66D948', 'k 	c #59CB3B', 'l 	c #5A6158', 'm 	c #9ECF91', 'n 	c #B1EAA2', 
'o 	c #D8F5D0', 'p 	c #DFF7D8', 'q 	c #E1F7DC', 'r 	c #DCF6D5', 's 	c #D5F4CD', 't 	c #C9F1BE', 
'u 	c #8CE374', 'v 	c #6DDB50', 'w 	c #5FD83F', 'x 	c #52C933', 'y 	c #595C58', 'z 	c #85B578', 
'A 	c #A7E797', 'B 	c #B8EDAA', 'C 	c #EAF9E6', 'D 	c #EEFAEB', 'E 	c #E7F9E2', 'F 	c #E0F7DA', 
'G 	c #D4F4CB', 'H 	c #C4F0B9', 'I 	c #B5EDA6', 'J 	c #81E067', 'K 	c #71DC55', 'L 	c #63D944', 
'M 	c #56D534', 'N 	c #4EAB35', 'O 	c #585858', 'P 	c #90BC84', 'Q 	c #9DE08B', 'R 	c #ADEB9C', 
'S 	c #F2FBF0', 'T 	c #F6FCF5', 'U 	c #F5FCF3', 'V 	c #F1FBEE', 'W 	c #DBF6D3', 'X 	c #CBF2C1', 
'Y 	c #A9EA97', 'Z 	c #97E582', '` 	c #58D637', ' .	c #4ED32A', '..	c #54744B', '+.	c #8BC07D', 
'@.	c #9CE589', '#.	c #FAFDFA', '$.	c #F3FCF1', '%.	c #EBFAE7', '&.	c #DDF6D7', '*.	c #CEF3C4', 
'=.	c #99E685', '-.	c #77DD5C', ';.	c #69DA4B', '>.	c #5AD639', ',.	c #4FD42B', '\'.	c #4BB72F', 
').	c #83B676', '!.	c #8BDD74', '~.	c #F9FDF8', '{.	c #4BCA29', '].	c #556750', '^.	c #6E9265', 
'/.	c #87E070', '(.	c #EFFBEC', '_.	c #E6F8E1', ':.	c #D9F5D2', '<.	c #4AC928', '[.	c #4D8A3D', 
'}.	c #66C04E', '|.	c #C7F1BC', '1.	c #D6F5CE', '2.	c #EDFAE9', '3.	c #C3F0B7', '4.	c #82E069', 
'5.	c #65D946', '6.	c #57D635', '7.	c #4DD12A', '8.	c #44B825', '9.	c #6CD150', '0.	c #7CDF62', 
'a.	c #8DE376', 'b.	c #9EE78A', 'c.	c #6FDB52', 'd.	c #61D841', 'e.	c #4CCF2A', 'f.	c #48C427', 
'g.	c #45BB26', 'h.	c #6AD64D', 'i.	c #B1ECA1', 'j.	c #BCEEAF', 'k.	c #5DD73C', 'l.	c #51D42F', 
'm.	c #4BCC29', 'n.	c #60CE42', 'o.	c #89E271', 'p.	c #95E580', 'q.	c #87E26F', 'r.	c #62D843', 
's.	c #47C027', 't.	c #43B625', 'u.	c #53BB38', 'v.	c #AAEA99', 'w.	c #A5E992', 'x.	c #4CCE29', 
'y.	c #46BD26', 'z.	c #41B023', 'A.	c #51973F', 'B.	c #85E16C', 'C.	c #98E683', 'D.	c #9BE687', 
'E.	c #5ED73E', 'F.	c #44BA25', 'G.	c #40AC23', 'H.	c #5B6858', 'I.	c #56D235', 'J.	c #43B524', 
'K.	c #53654E', 'L.	c #50BD32', 'M.	c #54D532', 'N.	c #5BD73A', 'O.	c #74DD58', 'P.	c #78DE5D', 
'Q.	c #597253', 'R.	c #4DCC2C', 'S.	c #53D530', 'T.	c #42B324', 'U.	c #507147', 'V.	c #4EA138', 
'W.	c #3FAB22', 'X.	c #49B82B', 'Y.	c #50D42D', 'Z.	c #40AE23', '`.	c #565B55', ' +	c #586056', 
'.+	c #48B52A', '++	c #48C227', '@+	c #49C528', '#+	c #41B124', '$+	c #555F52', '%+	c #585B57', 
'&+	c #489D31', '*+	c #46BF26', '=+	c #3EA922', '-+	c #52724A', ';+	c #45AA2A', '>+	c #4F7046', 
',+	c #546650', '\'+	c #4B853B', 
'                                                        ', 
'                                                        ', 
'                  . + @ # $ % & * =                     ', 
'              - ; > , \' ) ! ~ { ] ^ / (                 ', 
'            _ : < [ } } | 1 ) 2 3 ] 4 5 6 7             ', 
'          8 9 0 a b c c d e f \' 2 g h i j k l           ', 
'        m n 0 d o p q q r s t f ) ~ u 4 v w x y         ', 
'      z A B a o q C D D E F G H I 2 g J K L M N O       ', 
'    P Q R [ b p C S T U V E W X f Y Z ] i j `  ...      ', 
'    +.@.\' } G q D T #.#.$.%.&.*.| ) =.] -.;.>.,.\'.O     ', 
'  ).!.~ \' } c q D U #.~.$.C &.*.| ) =.] -.;.>.,.{.].    ', 
'  ^./.=.) | *.&.E S $.$.(._.:.X f Y Z ] i j `  .<.[.O   ', 
'  }.h 3 ! 1 |.1.q E 2.%.E &.c 3.I 2 { 4.K 5.6.7.<.8.O   ', 
'  9.0.a.b.\' | a s r p p W c |.f ) ~ u 0.c.d.M e.f.g.O   ',
'  h.-.] 3 2 i.j.e d b b d 3.f \' 2 { h -.;.k.l.m.f.g.O   ',
'  n.c.4 o.p.2 R I f [ | f I ) 2 p.q.4 c.r.6.7.<.s.t.O   ',
'  u.5.K 0.o.{ ~ ! v.) ) Y w.~ { q.0.K j k.l.x.f.y.z.O   ',
'  A.k.j K 4 B.a.{ C.D.D.C.{ a.B.4 K ;.E.M 7.<.s.F.G.O   ',
'  H.I.E.j c.-.0.h ] o.o.] h 0.-.c.j w M  .{.f.y.J.K.O   ',
'    L.M.N.r.;.c.O.-.P.P.-.O.c.;.r.k.M  .{.f.y.t.z.O     ',
'    Q.R.l.M k.d.5.;.;.;.;.5.r.k.6.S.7.{.f.y.F.T.U.O     ',
'      V.m.7.l.M ` >.k.k.N.` M S. .e.<.f.y.F.T.W.O       ',
'      y X.<.m.e.7.,.Y.Y.Y. .e.x.{.f.s.y.t.T.Z.`.O       ',
'         +.+++f.<.{.{.{.{.<.@+f.s.y.F.J.#+Z.$+O         ',
'          %+&+y.y.s.s.s.s.*+y.g.F.J.T.z.=+`.O           ',
'            O -+;+t.F.F.t.t.J.J.#+z.Z.>+O O             ',
'                O ,+\'+G.z.z.z.W.=+K.O O                 ',
'                    O O O O O O O O                     ',

        ],
    };
    
    return Wx::Bitmap->newFromXPM( $led->{$color} )
        if exists $led->{$color};
    
    return;
}



1;

