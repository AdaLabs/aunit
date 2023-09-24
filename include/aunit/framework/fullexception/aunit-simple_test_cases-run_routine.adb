------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--          A U N I T . T E S T _ C A S E S . R U N _ R O U T I N E         --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                                                                          --
--                    Copyright (C) 2006-2011, AdaCore                      --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT is maintained by AdaCore (http://www.adacore.com)                   --
--                                                                          --
------------------------------------------------------------------------------
--  TODO avoid use of Ada.Text_IO.Put_Line
--
with AUnit.IO;
with Ada.Exceptions;          use Ada.Exceptions;

with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;

with GNAT.Traceback.Symbolic; use GNAT.Traceback.Symbolic;

with AUnit.Time_Measure;

separate (AUnit.Simple_Test_Cases)

--  Version for run-time libraries that support exception handling
procedure Run_Routine
  (Test    : access Test_Case'Class;
   Options :        AUnit.Options.AUnit_Options;
   R       : in out Result'Class;
   Outcome :    out Status)
is
   File                 :  AUnit.IO.File_Type renames Options.Reporter_IO.all;
   Unexpected_Exception : Boolean := False;
   Exception_Occured    : Boolean := False;
   Time                 : Time_Measure.Time := Time_Measure.Null_Time;
   Assertion_Traceback  : Unbounded_String := Null_Unbounded_String;
   use Time_Measure;

begin

   --  Reset failure list to capture failed assertions for one routine

   Clear_Failures (Test.all);

   if Options.Enable_Test_Separators then
      AUnit.IO.Put_Line (File, "-------------------  begin " & Test.Name.all & "." & Test.Routine_Name.all);
   end if;

   if Options.Test_Case_Timer then
      Start_Measure (Time);
   end if;

   Set_Up (Test.all);

   begin

      Run_Test (Test.all);

   exception
      when E : Assertion_Error =>
         if Options.Test_Case_Timer then
            Stop_Measure (Time);
         end if;
         Assertion_Traceback := To_Unbounded_String (Symbolic_Traceback (E));
         Exception_Occured   := True;

      when E : others =>
         if Options.Test_Case_Timer then
            Stop_Measure (Time);
         end if;
         Exception_Occured    := True;
         Unexpected_Exception := True;

         Add_Error
           (R,
            Name (Test.all),
            Routine_Name (Test.all),
            Error => (Exception_Name    => Format (Exception_Name (E)),
                      Exception_Message => Format (Exception_Message (E)),
                      Traceback         => Format (Symbolic_Traceback (E))),
            Elapsed => Time);
   end;

   Tear_Down (Test.all);

   if not Exception_Occured and then Options.Test_Case_Timer then
      --  In case of Assertion_Error or Unexpected_Exception,
      --  the tear_down execution time is not taken into account
      --
      Stop_Measure (Time);
   end if;

   if not Unexpected_Exception and then not Has_Failures (Test.all) then
      Outcome := Success;
      Add_Success (R, Name (Test.all), Routine_Name (Test.all), Time);
   else
      Outcome := Failure;
      declare
         C : Failure_Iter := First_Failure (Test.all);
      begin
         while Has_Failure (C) loop
            declare
               Failure : AUnit.Test_Results.Test_Failure := Get_Failure (C);
            begin
               if Assertion_Traceback /= Null_Unbounded_String then
                  Failure.Traceback   := Format (To_String (Assertion_Traceback));
                  Assertion_Traceback := Null_Unbounded_String;
               end if;
               Add_Failure (R,
                            Name (Test.all),
                            Routine_Name (Test.all),
                            Failure,
                            Time);
            end;
            Next (C);
         end loop;
      end;
   end if;

   if Options.Enable_Test_Separators then
      AUnit.IO.Put_Line (File, "-------------------  end   " & Test.Name.all & "." & Test.Routine_Name.all);
   end if;

end Run_Routine;
