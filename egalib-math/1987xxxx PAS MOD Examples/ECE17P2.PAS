Program ECE17p2;


function z : real;

begin

  z := -3*x*x + -3*y*y + 300;

end; (* z *)


procedure CalcVolume ( a, b, c, d : real) : real;

var
  a, b, dx,
  c, d, dy  : real;

  function fi ( dx, dy, p, q : real ) : real;

  var
    x, y,
    fi,
    fi1, fi2,
    fi3, fi4  : real;

  begin

    x := a + p*dx;
    y := c + q*dy;
    fi1 := z;

    q := q + 1;
    y := c + q*dy;
    fi2 := z;

    p := p + 1;
    x := a + p*dx;
    fi3 := z;

    q := q - 1;
    y := c + q*dy;
    fi4 := z;

    fi := (fi1 + fi2 + fi3 + fi4) / 4;

  end; (* fi *)

begin

  while p <= (b - a) / dx do begin
    vx := fi(dx,dy,p,q)*dx*dy;
    vy := vy + vx;
    v := v + vy;
  end; (* while *)

end; (* CalcVolume *)



begin
  (* read in variables *)

