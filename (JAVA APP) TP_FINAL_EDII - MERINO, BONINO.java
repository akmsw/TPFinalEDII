/*
    ---TRABAJO PRACTICO FINAL INTEGRADOR - ELECTRONICA DIGITAL II---


    CODIGO PARA COMUNICACION CON PROTEUS POR PUERTO SERIE.


    UNC - FCEFyN - Junio, 2020.


    Ingenieria en computacion.


    @authors:   Merino, Mateo.
                Bonino, Francisco Ignacio
*/
import java.util.Scanner;

import java.io.File;
import java.io.FileWriter;
import java.io.BufferedWriter;

import giovynet.serial.Com;
import giovynet.serial.Baud;
import giovynet.serial.Parameters;

public class TXRXSPJavaForAssembly {

    private static boolean salir,salirRX,salirTX;
    private static char[] melody;
    private static String input,grabando,grabacion,folder,fileName,ruta;
    private static Scanner monitorScan;
    private static File file;
    private static FileWriter fw;
    private static BufferedWriter bw;
    private static Parameters params;
    private static Com serialPort;

    public static void main(String[] args) throws Exception {
        //Flags para salir de los bucles.
        salir = false;
        salirRX = false;
        salirTX = false;

        //Variable para lecturas por consola.
        monitorScan = new Scanner(System.in);

        //Parametros para la configuracion del puerto serie virtual
        params = new Parameters();

        System.out.println("\n--------------------------------TXRX de Java a PIC16F887--------------------------------\n");

        System.out.println("Ingrese el NÚMERO del puerto COM con el que trabajará para la transmisión serie:\n");

        input = monitorScan.nextLine();

        while(!checkInput(input)) {
            System.out.println("\nEntrada inválida.\nIngrese el NÚMERO del puerto COM con el que trabajará para la transmisión serie:\n");
            input = monitorScan.nextLine();
        }
        String port = "COM" + input;

        params.setPort(port);
        params.setBaudRate(Baud._9600);

        //Creacion del puerto serie virtual con las configuraciones establecidas.
        serialPort = new Com(params);

        while(!salir) {
            System.out.println("\nIngrese una opcion:\n1- Enviar partitura.\n2- Grabar melodia.\n3- Salir.\n");
        
            input = monitorScan.nextLine();

            while(!input.equals("1") && !input.equals("2") && !input.equals("3")) {
                System.out.println("Entrada invalida. Reingrese.\n");
                System.out.println("1- Enviar partitura.\n2- Grabar melodia.\n3- Salir.\n");
        
                input = monitorScan.nextLine();
            }

            if(input.equals("1")) {
                if(salirRX) salirRX = false;

                RX();
                
                System.out.println("\n--------------------------------------------------------------------------------\n");
            }
            else if(input.equals("2")) {
                if(salirTX) salirTX = false;

                TX();

                System.out.println("\n--------------------------------------------------------------------------------\n");
            }
            else salir = true;
        }

        System.exit(0);
    }

    /*
        Método para enviar partitura desde la PC al PIC16F887.
    */
    private static void RX() throws Exception {
        while(!salirRX) {
            System.out.print("\nIngrese una melodia para enviar: ");

            input = monitorScan.nextLine().toUpperCase();

            melody = input.toCharArray();

            //Validamos la entrada.
            while(input.length()>6 && !checkInput(melody)) {
                System.out.println("\nEntrada invalida. Debe ingresar 6 letras de la A a la G. Reingrese:\n");
                
                input = monitorScan.nextLine().toUpperCase();
                
                melody = input.toCharArray();
            }

            //Enviamos la entrada por puerto serie.
            for(int i = 5; i>-1; i--) {
                serialPort.sendSingleData(melody[i]);
            }

            System.out.println("\n1- Volver a menu principal.\n2- Reingresar melodia.\n");

            input = monitorScan.nextLine().toUpperCase();

            while(!validInput(input,"1","2")) {
                System.out.println("Entrada incorrecta. Reingrese:");
                System.out.println("\n1- Volver a menu principal.\n2- Reingresar melodia.\n");

                input = monitorScan.nextLine();
            }

            if(input.equals("1")) salirRX = true;
        }
    }

    /*
        Método para grabar desde el PIC16F887 a la PC.
    */
    private static void TX() throws Exception {
        getAddress();

        System.out.println("\n¿Desea cambiar la carpeta destino del archivo a grabar? (S/N)\n");
        input = monitorScan.nextLine().toUpperCase();

        while(!validInput(input,"S","N")) {
            System.out.println("\nEntrada incorrecta. Reingrese (S/N):\n");
            input = monitorScan.nextLine().toUpperCase();
        }

        if(input.equals("S")) {
            System.out.println("\nIngrese la nueva carpeta destino del archivo a grabar:\n");
            input = monitorScan.nextLine().toUpperCase();

            changeFolder(input);

            ruta = "C:/" + folder + "/" + fileName + ".txt";
        }

        System.out.println("\n¿Desea cambiar el nombre del archivo a grabar? (S/N)\n");
        input = monitorScan.nextLine().toUpperCase();

        while(!validInput(input,"S","N")) {
            System.out.println("\nEntrada incorrecta. Reingrese (S/N):\n");
            input = monitorScan.nextLine().toUpperCase();
        }

        if(input.equals("S")) {
            System.out.println("\nIngrese el nuevo nombre del archivo a grabar:\n");
            input = monitorScan.nextLine();

            changeFileName(input);

            ruta = "C:/" + folder + "/" + fileName + ".txt";
        }

        //Limpiamos 'grabacion' y la llenamos con lo que ingrese el usuario.
        grabacion = "";

        System.out.println("\nGrabando...\n\nNotas ingresadas:\n");

        while(!salirTX) {
            grabando = "";

            while(grabando.equals("")) {
                grabando = serialPort.receiveSingleString();
            }

            /*
                Convertimos el input a cifrado americano.

                A >> LA
                B >> SI
                C >> DO
                D >> RE
                E >> MI
                F >> FA
                G >> SOL
            */
            if(grabando.equals("w")) grabando = "A";
            else if(grabando.equals("|")) grabando = "B";
            else if(grabando.equals("9")) grabando = "C";
            else if(grabando.equals("^")) grabando = "D";
            else if(grabando.equals("y")) grabando = "E";
            else if(grabando.equals("q")) grabando = "F";
            else if(grabando.equals("=")) grabando = "G";
            else {
                salirTX = true;
                continue;
            }

            System.out.println(grabando);

            grabacion += grabando;
        }

        //Guardado del archivo.
        try {
            file = new File(ruta);
            
            if (!file.exists()) {
                file.createNewFile();
            }
            
            fw = new FileWriter(file);
            bw = new BufferedWriter(fw);
            bw.write(grabacion);
            bw.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        System.out.println("\nFin de grabacion. Resultado almacenado en " + folder + " con el nombre: '" + fileName + "'\n");
    }

    /*
        Método para especificar la ruta donde se almacenará la grabación, y su nombre.
    */
    private static void getAddress() {
        System.out.println("\nIngrese la carpeta donde almacenará el archivo de grabación (LA CARPETA DEBE HABER SIDO CREADA POR USTED EN EL DISCO C:):\n");
        folder = monitorScan.nextLine();

        System.out.println("\nIngrese el nombre con el que quiere almacenar el archivo:\n");
        fileName = monitorScan.nextLine();

        ruta = "C:/" + folder + "/" + fileName + ".txt";
    }

    /*
        @param  temp: Nombre de la nueva carpeta donde se almacenará la grabación.
    */
    private static void changeFolder(String temp) {
        folder = temp;
    }

    /*
        @param  temp: Nuevo nombre de la grabación.
    */
    private static void changeFileName(String temp) {
        fileName = temp;
    }

    /*
        @param  melody: Melodia ingresada por el usuario para enviar al PIC16F887.
    */
    private static boolean checkInput(char[] melody) {
        for(char letter : melody) {
            if(letter!='A' &&
               letter!='B' &&
               letter!='C' &&
               letter!='D' &&
               letter!='E' &&
               letter!='F' &&
               letter!='G')  return false;
        }
        return true;
    }

    private static boolean checkInput(String num) {
        if(!num.equals("1") &&
        !num.equals("2") &&
        !num.equals("3") &&
        !num.equals("4") &&
        !num.equals("5") &&
        !num.equals("6") &&
        !num.equals("7") &&
        !num.equals("8") &&
        !num.equals("9") )  return false;
        else return true;
    }

    /*
        @param  input: Input a validar.
                v1,v2: Valores con los cuales comparar el input del usuario para validarlo.
    */
    private static boolean validInput(String input, String v1, String v2) {
        if(!input.equals(v1) && !input.equals(v2)) return false;
        else return true;
    }
}