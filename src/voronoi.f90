PROGRAM voronoi
  IMPLICIT NONE
  INTEGER :: num_unitcell_points, num_total_points, stat, num_frames, dummy, num_atoms
  INTEGER :: num_atoms_per_molecule, i
  INTEGER, PARAMETER :: dim = 3
  !number of total points includes points in other periodic cells adjacent to the unit cell
  REAL(KIND=8), DIMENSION(:), ALLOCATABLE :: unitcell_dim
  REAL(KIND=8), DIMENSION(:, :), ALLOCATABLE :: points
  INTEGER, DIMENSION(:, :), ALLOCATABLE :: int_points
  !points of unit cell will be arranged in the array from the start
  INTEGER, PARAMETER :: input_fileid = 10
  CHARACTER(LEN=128) :: input_filename
  INTEGER, PARAMETER :: temp_data_fileid = 11
  CHARACTER(LEN=*), PARAMETER :: temp_data_filename = "data.tmp"
  INTEGER, PARAMETER :: temp_qvoronoi_fileid = 12
  CHARACTER(LEN=*), PARAMETER :: temp_qvoronoi_filename = "qvoronoi.tmp"
  INTEGER, PARAMETER :: temp_qhullinput_fileid = 13
  CHARACTER(LEN=*), PARAMETER :: temp_qhullinput_filename = "qhullinput.tmp"
  INTEGER, PARAMETER :: temp_qconvex_fileid = 14
  CHARACTER(LEN=*), PARAMETER :: temp_qconvex_filename = "qconvex.tmp"
  INTEGER, PARAMETER :: volume_result_fileid = 15
  CHARACTER(LEN=*), PARAMETER :: volume_result_filename = "volume.result"
  INTEGER, EXTERNAL :: count_num_data_in_line

  !check if qhull binary files are in the system PATH
  !NOTE: The return value "stat" of function SYSTEM() is compiler dependent.
  !      One have to refer to the compiler's manual to see if it is supported.
  !      The syntax here is acceptable for compiler "gfortran", but unacceptable for "ifort".
  !      If it is sure that qhull binaries are installed correctly in system PATH,
  !      one can simply comment out or delete this "call SYSTEM()" paragraph 
  !      since it is only written for checking.
  !------- Delete from here if the compiler does not support return value "stat" ------!
  call SYSTEM("which qhull > /dev/null", stat)
  if (stat/=0) then
     write(*,*) "Error: please set qhull binaries (including qvoronoi ..., etc.)&
          & in your system PATH."
     call EXIT(1)
  end if
  !------- Delete until here -----------------------------------------------------------!

  call read_initial_data()
  ! open output file
  open(UNIT=volume_result_fileid, FILE=volume_result_filename, IOSTAT=stat,&
       & STATUS='REPLACE', ACTION='WRITE')
  if (stat /= 0) then
     write(*,*) "Error: unable to create file: ", volume_result_filename
     call EXIT(1)
  end if
    
  do i = 1, num_frames
     call read_data()
     call generate_periodic_data()
     call output_temp_datafile() !output temp file for external program qhull
     call use_qhull()
     write(*,"(I3,'% is done')") INT(REAL(i)/REAL(num_frames)*100)
  end do
  call clean() !delete the used temp files. 
                        !For the purpose of debugging, one can comment out this subroutine call

CONTAINS
  SUBROUTINE read_initial_data()
    IMPLICIT NONE
    INTEGER :: stat, i
    CHARACTER(LEN=128) :: command

    !read the input file name from command line argument
    call GET_COMMAND_ARGUMENT(NUMBER=1, VALUE=input_filename, STATUS=stat)
    if (stat /= 0) then
       call GET_COMMAND_ARGUMENT(NUMBER=0, VALUE=command)
       write(*,*) "Usage: " // TRIM(ADJUSTL(command)) // " data_file"
       call EXIT(1)
    end if

    open(UNIT=input_fileid, FILE=input_filename, STATUS='OLD', IOSTAT=stat, ACTION='READ')
    if (stat /= 0) then
       write(*,*) "Error: unable to open file: ", input_filename
       call EXIT(1)
    end if

    read(input_fileid, *) num_frames, dummy, dummy, num_atoms
    write(*,*) "num_frames:", num_frames !output
    write(*,*) "num_atoms:", num_atoms !output

    do i=1,7 !ignore 7 lines of HISTORY file
       read(input_fileid, *)
    end do
    read(input_fileid, *) num_unitcell_points
    read(input_fileid, *) num_atoms_per_molecule
    
    write(*,*) "num_unitcell_points:", num_unitcell_points
    write(*,*) "num_atoms_per_molecule:", num_atoms_per_molecule
    
    num_total_points = num_unitcell_points * (dim ** dim)

    allocate(points(num_total_points, dim), STAT=stat)
    if (stat /= 0 ) then
       write(*,*) "Error: allocating points() fail."
       call EXIT(1)
    end if

    allocate(int_points(num_total_points, dim), STAT=stat)
    if (stat /= 0 ) then
       write(*,*) "Error: allocating int_points() fail."
       call EXIT(1)
    end if
  END SUBROUTINE read_initial_data
  
  SUBROUTINE read_data()
    IMPLICIT NONE
    INTEGER :: stat, i, j
    
    allocate(unitcell_dim(dim), STAT=stat)
    if (stat /= 0 ) then
       write(*,*) "Error: allocating unitcell_dim() fail."
       call EXIT(1)
    end if

    read(input_fileid, *) unitcell_dim(1)
    read(input_fileid, *) unitcell_dim(2), unitcell_dim(2)
    read(input_fileid, *) unitcell_dim(3), unitcell_dim(3), unitcell_dim(3)
!    write(*,*) unitcell_dim !output

    do i = 1, num_unitcell_points
       call intre2(input_fileid, 1, int_points(i,1), int_points(i,2), int_points(i,3),&
            & points(i,1), points(i,2), points(i,3))
       do j = 1, num_atoms_per_molecule - 1
          read(input_fileid, *)
       end do
    end do

    ! skip other non voronoi atoms
    do i = 1, num_atoms - num_unitcell_points * num_atoms_per_molecule
       read(input_fileid, *)
    end do
 !   write(*,*) points(1,:) !output
  END SUBROUTINE read_data

  SUBROUTINE generate_periodic_data()
    IMPLICIT NONE
    INTEGER :: i, j, k, Cell_index, ii, jj, kk
    !1: minus unit cell dim, 2: plus unit cell dim, 0: stay the same
    !cell_index: turn a base-3 number into a base-10 number
    do i = 0, 2
       do j = 0, 2
          do k = 0, 2
             if (i==0 .AND. j==0 .AND. k==0) then !unit cell need no change
                CYCLE
             end if
             cell_index = dim**2 * i + dim**1 * j + dim**0 * k
             !change 1 to -1, 2 to 1 and 0 remains 0
             if (i > 0) then
                ii = i*2 - 3
             else
                ii = 0
             end if
             if (j > 0) then
                jj = j*2 - 3
             else
                jj = 0
             end if
             if (k > 0) then
                kk = k*2 - 3
             else
                kk = 0
             end if
             !for x-direction (i-direction)
             points(num_unitcell_points * cell_index + 1 : &
                  & num_unitcell_points * (cell_index + 1), 1) = &
                  & points(1:num_unitcell_points, 1) + unitcell_dim(1) * ii
             !for y-direction (j-direction)
             points(num_unitcell_points * cell_index + 1 : &
                  & num_unitcell_points * (cell_index + 1), 2) = &
                  & points(1:num_unitcell_points, 2) + unitcell_dim(2) * jj
             !for z-direction (k-direction)
             points(num_unitcell_points * cell_index + 1 : &
                  & num_unitcell_points * (cell_index + 1), 3) = &
                  & points(1:num_unitcell_points, 3) + unitcell_dim(3) * kk
          end do
       end do
    end do
    deallocate(unitcell_dim)
  END SUBROUTINE generate_periodic_data

  SUBROUTINE output_temp_datafile()
    IMPLICIT NONE
    INTEGER :: i, stat
    open(UNIT=temp_data_fileid, FILE=temp_data_filename, IOSTAT=stat,&
         & STATUS='REPLACE', ACTION='WRITE')
    if (stat /= 0) then
       write(*,*) "Error: unable to create temp file: ", temp_data_filename
       call EXIT(1)
    end if

    write(UNIT=temp_data_fileid, FMT=*) dim
    write(UNIT=temp_data_fileid, FMT=*) num_total_points
    do i = 1, num_total_points
       write(UNIT=temp_data_fileid, FMT=*) points(i,:)
    end do
    close(UNIT=temp_data_fileid, STATUS='KEEP')
  END SUBROUTINE output_temp_datafile

  SUBROUTINE use_qhull()
    IMPLICIT NONE
    INTEGER :: i, stat, num_data_in_line, num_voronoi_vertices
    INTEGER, DIMENSION(:), ALLOCATABLE :: voronoi_region
    REAL(KIND=8), DIMENSION(:, :), ALLOCATABLE :: voronoi_vertices
    CHARACTER(LEN=1024) :: line
    REAL(KIND=8), DIMENSION(:), ALLOCATABLE :: density
    REAL(KIND=8) :: volume

    call SYSTEM("qvoronoi o < " // temp_data_filename // " > " // temp_qvoronoi_filename)

    open(UNIT=temp_qvoronoi_fileid, FILE=temp_qvoronoi_filename, IOSTAT=stat,&
         & STATUS='OLD', ACTION='READ')
    if (stat /= 0) then
       write(*,*) "Error: unable to open temp file: ", temp_qvoronoi_filename
       call EXIT(1)
    end if

!     write(UNIT=volume_result_fileid, FMT=*) "Volumes report"
!     write(UNIT=volume_result_fileid, FMT=*) "Region Site: Volume Density"
!     write(UNIT=volume_result_fileid, FMT=*) "================================"

    read(UNIT=temp_qvoronoi_fileid, FMT=*) !we don't need dimension info now
    read(UNIT=temp_qvoronoi_fileid, FMT=*) num_voronoi_vertices
    read(UNIT=temp_qvoronoi_fileid, FMT=*) !ignore the first vertex which is INF
    num_voronoi_vertices = num_voronoi_vertices - 1 !remove the INF vertex
    allocate(voronoi_vertices(num_voronoi_vertices, dim), STAT=stat)
    if (stat /= 0 ) then
       write(*,*) "Error: allocating num_voronoi_vertices() fail."
       call EXIT(1)
    end if

    !read voronoi vertices
    do i = 1, num_voronoi_vertices
       read(UNIT=temp_qvoronoi_fileid, FMT=*) voronoi_vertices(i, :)
    end do

    allocate(voronoi_region(num_voronoi_vertices), STAT=stat)
    if (stat /= 0 ) then
       write(*,*) "Error: allocating voronoi_region() fail."
       call EXIT(1)
    end if

    allocate(density(num_unitcell_points), STAT=stat)
    if (stat /= 0 ) then
       write(*,*) "Error: allocating density() fail."
       call EXIT(1)
    end if

    !read voronoi region one by one and simultaneously use qhull to calculate its volume
    do i = 1, num_unitcell_points
       ! initialze array with -1, representing no datum in that element
       voronoi_region = -1
       read(UNIT=temp_qvoronoi_fileid, FMT="(A)") line
       num_data_in_line = count_num_data_in_line(line)
       read(UNIT=line, FMT=*, IOSTAT=stat) voronoi_region(1:num_data_in_line)
       if (stat < 0) then ! end of file reached
          write(*,*) "Error: use_qhull(): number of counted data&
               & is greater than number of actual data."
       end if
       if (ANY(voronoi_region(1:num_data_in_line) == 0)) then
          write(*,*) "Warning: voronoi region site #",i," has an infinite volume."
       else
          call output_temp_qhullinputfile(voronoi_vertices, voronoi_region(1:num_data_in_line))
          call SYSTEM("qhull FA < " // temp_qhullinput_filename // " > " // temp_qconvex_filename)
          open(UNIT=temp_qconvex_fileid, FILE=temp_qconvex_filename, IOSTAT=stat,&
               & STATUS='OLD', ACTION='READ')
          if (stat /= 0) then
             write(*,*) "Error: unable to open temp file: ", temp_qconvex_filename
             call EXIT(1)
          end if
          call get_volume(temp_qconvex_fileid, temp_qconvex_filename, volume)
          density(i) = 1./volume
!          write(UNIT=volume_result_fileid, FMT=*) "Region ", i, ":", volume, density(i)
          close(UNIT=temp_qconvex_fileid, STATUS='KEEP')
       end if
    end do
    write(UNIT=volume_result_fileid, FMT=*) "Average density:", SUM(density)/SIZE(density)

    deallocate(voronoi_region)
    deallocate(voronoi_vertices)
    deallocate(density)
    close(UNIT=temp_qvoronoi_fileid, STATUS='KEEP')
  END SUBROUTINE use_qhull

  SUBROUTINE output_temp_qhullinputfile(vertices, region)
    IMPLICIT NONE
    INTEGER :: stat, i
    REAL(KIND=8), DIMENSION(:, :), INTENT(IN) :: vertices
    INTEGER, DIMENSION(:), INTENT(IN) :: region

    open(UNIT=temp_qhullinput_fileid, FILE=temp_qhullinput_filename, IOSTAT=stat,&
         & STATUS='REPLACE', ACTION='WRITE')
    if (stat /= 0) then
       write(*,*) "Error: unable to open temp file: ", temp_qhullinput_filename
       call EXIT(1)
    end if
    write(UNIT=temp_qhullinput_fileid, FMT=*) dim
    write(UNIT=temp_qhullinput_fileid, FMT=*) region(1)
    ! region(1) is the number of vertices, the rest are indexes of vertices
    ! i.e. region(1) == size(region) - 1
    do i = 2, size(region)
       write(UNIT=temp_qhullinput_fileid, FMT=*) vertices(region(i), :)
    end do
    close(UNIT=temp_qhullinput_fileid, STATUS='KEEP')
  END SUBROUTINE output_temp_qhullinputfile

  SUBROUTINE get_volume(fileid, filename, volume)
    ! extract the value of volume in file
    IMPLICIT NONE
    INTEGER, INTENT(IN) :: fileid
    CHARACTER(LEN=*) :: filename
    REAL(KIND=8), INTENT(OUT) :: volume
    CHARACTER(LEN=128) :: line
    INTEGER :: stat

    do while (.TRUE.)
       read(UNIT=fileid, FMT="(A)", IOSTAT=stat) line
       if (stat/=0) then
          write(*,*) "line=*"// line // "*"
          write(*,*) "Error: get_volume(file): there is no keyword 'volume:' in file, ", filename
          call EXIT(1)
       end if
       if (INDEX(line, "volume:") > 0) then
          read(UNIT=line(INDEX(line, ':') + 1:), FMT=*) volume
          RETURN
       end if
    end do
  END SUBROUTINE get_volume

  SUBROUTINE clean()
    IMPLICIT NONE
    close(UNIT=input_fileid)
    
    open(UNIT=temp_data_fileid, FILE=temp_data_filename)
    close(UNIT=temp_data_fileid, STATUS='DELETE')
    open(UNIT=temp_qvoronoi_fileid, FILE=temp_qvoronoi_filename)
    close(UNIT=temp_qvoronoi_fileid, STATUS='DELETE')
    open(UNIT=temp_qhullinput_fileid, FILE=temp_qhullinput_filename)
    close(UNIT=temp_qhullinput_fileid, STATUS='DELETE')
    open(UNIT=temp_qconvex_fileid, FILE=temp_qconvex_filename)
    close(UNIT=temp_qconvex_fileid, STATUS='DELETE')

    close(UNIT=volume_result_fileid, STATUS='KEEP')
    deallocate(points)
  END SUBROUTINE clean
END PROGRAM voronoi

FUNCTION count_num_data_in_line(line)
  ! count number of data (vertex) in a line (voronoi region)
  ! with the knowledge that each datum is separated by a space
  IMPLICIT NONE
  INTEGER :: count_num_data_in_line
  CHARACTER(LEN=*), INTENT(IN) :: line
  INTEGER :: i
  LOGICAL :: is_previous_space = .FALSE.

  count_num_data_in_line = 0
  do i = 1, LEN(line)
     if (line(i:i) == ' ') then
        if (i == 1) then
           ! no datum in this line
           write(*,*) "Error: count_num_data_in_line(): no data in a line"
           call EXIT(1)
        else if (is_previous_space) then
           ! double spaces mean the end of data is reached
           RETURN
        else
           ! count one datum
           count_num_data_in_line = count_num_data_in_line + 1
           is_previous_space = .TRUE.
        end if
     else
        is_previous_space = .FALSE.
     end if
  end do
  ! no double spaces occur, probably the line is not long enough
  write(*,*) "Error: count_num_data_in_line(): the defined length of&
       & a line for reading is not long enough."
  call EXIT(1)
END FUNCTION count_num_data_in_line
