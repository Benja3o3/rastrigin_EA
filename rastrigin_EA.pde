PImage rastrigin;
int DIM = 2; // Dimensiones de la funcion Rastrigin
int w = 200; // Variable de biodiversidad (w++ Mas diversidad, w-- Menos diversidad) (200 Ok)
float coef_genetica_1 = 0.7; // Coeficiente de concentracion en las caracteristicas de la particula con mejor fit
float coef_genetica_2 = 1 - coef_genetica_1;

int puntos = 20; // Cantidad de "animales" en el plano
float total_fitness = 0.0; // Fitness total, usado para calcular las probabilidades
Animal[] A; // Arreglo de puntos
float d = 15; // Radio del circulo (despliegue)
float gbestx,gbesty,bestx,besty,best=1000; //Solo para el despliegue
int gens = 0; // Generaciones transcurridas
int gens_to_the_best = 0; // Generaciones transcurridas hasta encontrar el mejor fit


class Animal{
    float x,y,fit,prob,prob_acum; // Posicion en el plano (Representan caracteristicas, ejemplo ADN)
    float evalx,evaly; // Con estos numeros se evalua en el dominio [-3,7]

    //--Constructor de la inicializacion
    Animal(){
      x = random(width); y = random(height);
      evalx = (x-300)/100.0; evaly = (y-300)/100.0;
      fit = rastrigin(evalx,evaly);
    }

    //--Constructor usado para el cruce de particulas
    Animal(Animal a, Animal b){
      float cx,cy; // Punto entre a y b sobre el cual se generar un nuevo hijo
      // Si a es mejor que b se cargan las caracteristicas de los hijos hacia a, y viceversa
      if (a.fit > b.fit){
        cx = a.x * coef_genetica_1 + b.x * coef_genetica_2;
        cy = a.y * coef_genetica_1 + b.y * coef_genetica_2;
      }
      else{
        cx = a.x * coef_genetica_2 + b.x * coef_genetica_1;
        cy = a.y * coef_genetica_2 + b.y * coef_genetica_1;          
      }
      // Se calcula la posicion del hijo, la cual estara en un cuadrado alredeor del punto (cx,cy)
      // Esto para dar mayor diversidad al hijo, dando mayor "exploracion" en el plano
      x = random(cx - w,cx + w); y = random(cy - w, cy + w);

      if (x<0) x = 0; if (x>1000) x=1000; if (y<0) y = 0; if (y>1000) y = 1000; // Esto para que no se salga de los limites
      // Se calcula el fit usando la funcion
      evalx = (x-300)/100.0; evaly = (y-300)/100.0;
      fit = rastrigin(evalx,evaly);
      // Si el fit de la particula es mejor que el que ya se tenia, se actualizan los datos
      if (fit < best){
        best = fit;
        bestx = evalx;
        besty = evaly;
        gbestx = x;
        gbesty = y;
        gens_to_the_best = gens;
      }
    }

    //Funcion de display para ver las particulas en la pantalla
    void display(int r,int g,int b){
      fill(r,g,b);
      ellipse (x,y,d,d);
    }
}

// Funcion que evalua dos puntos segun la funcion Rastrigin
float rastrigin(float x,float y){
  float sum = 10*DIM;
  sum += pow(x, 2) - 10*cos(2*PI*x);
  sum += pow(y, 2) - 10*cos(2*PI*y);
  return sum; 
}

void setup(){  
  //Se setea la ventana con la funcion rastrigin pintada de fondo
  size(1000,1000);
  rastrigin = createImage(1000, 1000, RGB);
  rastrigin.loadPixels();
  for (int i = 0; i < 1000; i++) {
    for (int j = 0; j < 1000; j++){
      float val = rastrigin((i-300)/100.0,(j-300)/100.0);
      rastrigin.pixels[i*1000+j] = color(0,val*3,255-(val*3));
    } 
  }
  rastrigin.updatePixels();
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  smooth();
  //Inicializa la generacion 0 de particulas
  A = new Animal[puntos];
  for(int i =0;i<puntos;i++)
    A[i] = new Animal();
}

//Funcion que selecciona las mejores particulas dentro del arreglo siguiendo el metodo probabilistico encontrado en el libro
//Michalewicz Z. Genetic Algorithms + Data Structures Parte 1 Capitulo 2
Animal[] Selection(Animal[] A){
  total_fitness = 0.0;
  Animal[] B = new Animal[puntos]; // Se crea un nuevo arreglo que contendra a la mejor seleccion
  // Se calcula el total fitness inverso (como se esta minimizando queremos que los menores valores sean mejor valorados)
  for (Animal i : A){
    total_fitness += 1/i.fit;
  }
  // Se calcula la probabilidad de cada particula en base a su fit
  for (Animal i : A){
    i.prob = (1/i.fit)/total_fitness;
  }
  // Se calcula la probabilidad acumulada de cada particula
  for (int i = 0; i < puntos; i++){
    if (i == 0) A[i].prob_acum = A[i].prob; 
    else A[i].prob_acum = A[i].prob + A[i-1].prob_acum;
  }
  // Se genera un valor aleatorio entre 0 y 1 y se agrega al arreglo la particula que tenga probabilidad acumulada
  // inmediatamente mayor al valor generado. Se itera hasta llenar el arreglo nuevo
  for (int i = 0; i < puntos; i++){
    int c = 0;
    float val = random(0,1);
    while (val > A[c].prob_acum){
      c++;
    }
    B[i] = A[c];
  }
  return B;
}

// Funcion de cruzamiento que toma dos particulas y genera dos hijos nuevos en base a esas dos
Animal[] Cruzamiento(Animal[] A){
  Animal[] C = new Animal[puntos]; // Se crea un arreglo para los hijos
  int c = 0;
  while (c < puntos){
    //Se elijen dos particulas al azar
    int a1=int(random(A.length)),a2=int(random(A.length));
    Animal x = A[a1];
    Animal y = A[a2];
    
    //Se cruzan, cargando hacia la particula con mejores caracteristicas (fit)
    Animal z = new Animal(x,y);
    Animal w = new Animal(x,y);
    //Se agregan al arreglo
    C[c] = z;
    c++;
    C[c] = w;
    c++;
    // Se eliminan las particulas padre para que no se repitan
    Animal[] tempArray = new Animal[A.length - 1];
    System.arraycopy(A, 0, tempArray, 0, a1);
    System.arraycopy(A, a1 + 1, tempArray, a1, A.length - a1 - 1);
    A = tempArray;
  }
  return C;
}

// Proceso del algoritmo
void draw(){
  image(rastrigin,0,0);
  dibujarPlano();
  muestraDatos();
  for(int i = 0;i<puntos;i++){
    A[i].display(255,0,0);
  }
  A = Selection(A);
  A = Cruzamiento(A);
  gens++;
}

//Funcion que dibuja el plano cartesiano en la ventana
void dibujarPlano(){
  stroke(0);
  strokeWeight(2);
  line(0,300,1000,300);
  line(300,0,300,1000);
  for (int i = 0; i < 10; i++){
    line(i*100,297,i*100,303);
    line(297,i*100,303,i*100);
  }
}

//Funcion para mostrar datos relevantes del algoritmo
void muestraDatos(){
  fill(255,255,255);
  ellipse(gbestx,gbesty,d,d);
  PFont f = createFont("Arial",16,true);
  fill(0,0,0);
  textFont(f,20);
  text("Mejor fitness : "+str(best)+"\nMejor posicion : ("+str(bestx)+","+str(besty)+")"+"\nGeneraciones hasta el mejor: "+str(gens_to_the_best)+"\nGeneracion "+str(gens),10,900);
}