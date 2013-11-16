#!/usr/bin/perl

open IN, "<cvg_routines.tex";
open OUT, ">cvg_routines_sorted.tex";

$text = "";
while( $line = <IN> ) {
   chomp $line;
   if( $line =~ /sstroutine/ ) {
      if( $text ) {
         $routines{$name} = "$text\n";
      }
      $text = $line;
      $state = 1;
   } else {
      $text .= "\n$line";
      if( $state ==  1 ) {
         $name = $line;
         $state = 0;
      }
   }
}

$routines{$name} = "$text\n";

foreach $key (sort keys %routines) {
   print OUT $routines{$key};
}

close( IN );
close( OUT );


