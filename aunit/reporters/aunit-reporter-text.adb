------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                   A U N I T . R E P O R T E R . T E X T                  --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                                                                          --
--                       Copyright (C) 2000-2009, AdaCore                   --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
-- to  the  Free Software Foundation,  51  Franklin  Street,  Fifth  Floor, --
-- Boston, MA 02110-1301, USA.                                              --
--                                                                          --
-- GNAT is maintained by AdaCore (http://www.adacore.com)                   --
--                                                                          --
------------------------------------------------------------------------------

with GNAT.IO;            use GNAT.IO;
with AUnit.Time_Measure; use AUnit.Time_Measure;

--  Very simple reporter to console
package body AUnit.Reporter.Text is

   procedure Indent (N : Natural);
   --  Print N indentations to output

   procedure Dump_Result_List (L : Result_Lists.List; Prefix : String);
   --  Dump a result list

   procedure Put_Measure is new Gen_Put_Measure;
   --  Output elapsed time

   procedure Report_Test (Test : Test_Result; Prefix : String);
   --  Report a single assertion failure or unexpected exception

   ANSI_Def    : constant String := ASCII.ESC & "[0m";
   ANSI_Green  : constant String := ASCII.ESC & "[32m";
   ANSI_Purple : constant String := ASCII.ESC & "[35m";
   ANSI_Red    : constant String := ASCII.ESC & "[31m";

   -------------------------
   -- Set_Use_ANSI_Colors --
   -------------------------

   procedure Set_Use_ANSI_Colors
     (Engine : in out Text_Reporter;
      Value  : Boolean) is
   begin
      Engine.Use_ANSI := Value;
   end Set_Use_ANSI_Colors;

   ------------
   -- Indent --
   ------------

   procedure Indent (N : Natural) is
   begin
      for J in 1 .. N loop
         Put ("    ");
      end loop;
   end Indent;

   ----------------------
   -- Dump_Result_List --
   ----------------------

   procedure Dump_Result_List (L : Result_Lists.List; Prefix : String) is

      use Result_Lists;

      C : Cursor := First (L);
   begin
      if Has_Element (C) then
         New_Line;
      end if;

      --  Note: can't use Iterate because it violates restriction
      --  No_Implicit_Dynamic_Code

      while Has_Element (C) loop
         Report_Test (Element (C), Prefix);
         Next (C);
      end loop;
   end Dump_Result_List;

   ------------
   -- Report --
   ------------

   procedure Report
     (Engine : Text_Reporter;
      R      : in out Result'Class)
   is
      T : AUnit_Duration;
      S : Result_Lists.List;
      F : Result_Lists.List;
      E : Result_Lists.List;
   begin
      Successes (R, S);
      Failures (R, F);
      Errors (R, E);

      if Engine.Use_ANSI then
         Put (ANSI_Green);
      end if;

      Dump_Result_List (S, "OK");

      if Engine.Use_ANSI then
         Put (ANSI_Def);
      end if;

      if Engine.Use_ANSI then
         Put (ANSI_Purple);
      end if;

      Dump_Result_List (F, "FAIL");

      if Engine.Use_ANSI then
         Put (ANSI_Def);
      end if;

      if Engine.Use_ANSI then
         Put (ANSI_Red);
      end if;

      Dump_Result_List (E, "ERROR");

      if Engine.Use_ANSI then
         Put (ANSI_Def);
      end if;

      New_Line;
      Put ("Total Tests Run:   ");
      Put (Integer (Test_Count (R)));
      New_Line;
      Put ("Successful Tests:  ");
      Put (Integer (Result_Lists.Length (S)));
      New_Line;
      Put ("Failed Assertions: ");
      Put (Integer (Result_Lists.Length (F)));
      New_Line;
      Put ("Unexpected Errors: ");
      Put (Integer (Result_Lists.Length (E)));
      New_Line;

      if Elapsed  (R) /= Time_Measure.Null_Time then
         T := Get_Measure (Elapsed (R));

         Put ("Cumulative Time: ");
         Put_Measure (T);
         Put_Line (" seconds");
      end if;
   end Report;

   -----------------
   -- Report_Test --
   -----------------

   procedure Report_Test (Test : Test_Result; Prefix : String) is
      T : AUnit_Duration;
   begin
      Put (Prefix);
      Put (" ");
      Put (Test.Test_Name.all);

      if Test.Routine_Name /= null then
         Put (" : ");
         Put (Test.Routine_Name.all);
      end if;

      if Test.Elapsed /= Time_Measure.Null_Time then
         Put (" (in ");
         T := Get_Measure (Test.Elapsed);
         Put_Measure (T);
         Put ("s)");
      end if;

      New_Line;

      if Test.Failure /= null then
         Indent (1);
         Put_Line (Test.Failure.Message.all);
         Indent (1);
         Put ("at ");
         Put (Test.Failure.Source_Name.all);
         Put (":");
         Put (Test.Failure.Line);
         New_Line;

      elsif Test.Error /= null then
         Indent (1);
         Put_Line (Test.Error.Exception_Name.all);

         if Test.Error.Exception_Message /= null then
            Indent (1);
            Put      ("Exception Message: ");
            Put_Line (Test.Error.Exception_Message.all);
         end if;

         if Test.Error.Traceback /= null then
            Indent (1);
            Put_Line ("Traceback:");

            declare
               From, To : Natural := Test.Error.Traceback'First;
            begin
               while From <= Test.Error.Traceback'Last loop
                  To := From;
                  while To <= Test.Error.Traceback'Last
                    and then Test.Error.Traceback (To) /= ASCII.LF
                  loop
                     To := To + 1;
                  end loop;

                  Indent (2);
                  Put_Line (Test.Error.Traceback (From .. To - 1));
                  From := To + 1;
               end loop;
            end;
         end if;

         New_Line;
      end if;
   end Report_Test;

end AUnit.Reporter.Text;
