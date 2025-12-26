import '../models/quote.dart';

/// Frases iniciales para cargar en la base de datos
class InitialQuotes {
  static List<Quote> getQuotes() {
    return [
      // MOTIVACIÓN
      Quote(
        text:
            'El éxito es la suma de pequeños esfuerzos repetidos día tras día.',
        author: 'Robert Collier',
        category: 'Motivación',
      ),
      Quote(
        text: 'No importa lo lento que vayas, siempre y cuando no te detengas.',
        author: 'Confucio',
        category: 'Motivación',
      ),
      Quote(
        text: 'La única manera de hacer un gran trabajo es amar lo que haces.',
        author: 'Steve Jobs',
        category: 'Motivación',
      ),
      Quote(
        text:
            'El futuro pertenece a quienes creen en la belleza de sus sueños.',
        author: 'Eleanor Roosevelt',
        category: 'Motivación',
      ),
      Quote(
        text: 'No cuentes los días, haz que los días cuenten.',
        author: 'Muhammad Ali',
        category: 'Motivación',
      ),

      // BIENESTAR
      Quote(
        text: 'La felicidad no es algo hecho. Viene de tus propias acciones.',
        author: 'Dalai Lama',
        category: 'Bienestar',
      ),
      Quote(
        text: 'Cuida tu cuerpo. Es el único lugar que tienes para vivir.',
        author: 'Jim Rohn',
        category: 'Bienestar',
      ),
      Quote(
        text: 'La paz viene de dentro. No la busques fuera.',
        author: 'Buda',
        category: 'Bienestar',
      ),
      Quote(
        text: 'El bienestar es un estado mental que elegimos crear.',
        author: 'Anónimo',
        category: 'Bienestar',
      ),
      Quote(
        text: 'Respira. Estás vivo. Relájate.',
        author: 'Thich Nhat Hanh',
        category: 'Bienestar',
      ),

      // PRODUCTIVIDAD
      Quote(
        text: 'La única forma de hacer un gran trabajo es amar lo que haces.',
        author: 'Steve Jobs',
        category: 'Productividad',
      ),
      Quote(
        text: 'No esperes. El momento nunca será perfecto.',
        author: 'Napoleon Hill',
        category: 'Productividad',
      ),
      Quote(
        text: 'El secreto está en comenzar.',
        author: 'Mark Twain',
        category: 'Productividad',
      ),
      Quote(
        text: 'Concéntrate en ser productivo en lugar de estar ocupado.',
        author: 'Tim Ferriss',
        category: 'Productividad',
      ),
      Quote(
        text: 'La acción es la llave fundamental de todo éxito.',
        author: 'Pablo Picasso',
        category: 'Productividad',
      ),

      // RELACIONES
      Quote(
        text:
            'La mejor forma de encontrarte a ti mismo es perderte en el servicio a los demás.',
        author: 'Mahatma Gandhi',
        category: 'Relaciones',
      ),
      Quote(
        text:
            'Las personas olvidarán lo que dijiste, pero nunca olvidarán cómo las hiciste sentir.',
        author: 'Maya Angelou',
        category: 'Relaciones',
      ),
      Quote(
        text: 'La empatía es ver con los ojos del otro.',
        author: 'Alfred Adler',
        category: 'Relaciones',
      ),
      Quote(
        text:
            'El amor es la única fuerza capaz de transformar a un enemigo en amigo.',
        author: 'Martin Luther King Jr.',
        category: 'Relaciones',
      ),
      Quote(
        text: 'Sé amable siempre que sea posible. Siempre es posible.',
        author: 'Dalai Lama',
        category: 'Relaciones',
      ),

      // METAS
      Quote(
        text: 'Un objetivo sin un plan es solo un deseo.',
        author: 'Antoine de Saint-Exupéry',
        category: 'Metas',
      ),
      Quote(
        text: 'No importa qué tan lento vayas mientras no te detengas.',
        author: 'Confucio',
        category: 'Metas',
      ),
      Quote(
        text:
            'El único límite para nuestros logros de mañana está en nuestras dudas de hoy.',
        author: 'Franklin D. Roosevelt',
        category: 'Metas',
      ),
      Quote(
        text:
            'Establece metas que te hagan querer saltar de la cama por la mañana.',
        author: 'Anónimo',
        category: 'Metas',
      ),
      Quote(
        text:
            'El éxito no es la clave de la felicidad. La felicidad es la clave del éxito.',
        author: 'Albert Schweitzer',
        category: 'Metas',
      ),

      // MENTALIDAD
      Quote(
        text: 'La mente lo es todo. Te conviertes en lo que piensas.',
        author: 'Buda',
        category: 'Mentalidad',
      ),
      Quote(
        text: 'Cambia tus pensamientos y cambiarás tu mundo.',
        author: 'Norman Vincent Peale',
        category: 'Mentalidad',
      ),
      Quote(
        text: 'No se trata de tener tiempo. Se trata de hacer tiempo.',
        author: 'Anónimo',
        category: 'Mentalidad',
      ),
      Quote(
        text: 'La actitud es una pequeña cosa que marca una gran diferencia.',
        author: 'Winston Churchill',
        category: 'Mentalidad',
      ),
      Quote(
        text: 'La vida es 10% lo que te sucede y 90% cómo reaccionas a ello.',
        author: 'Charles R. Swindoll',
        category: 'Mentalidad',
      ),

      // MÁS FRASES...
      Quote(
        text: 'Cree en ti mismo y todo será posible.',
        author: 'Anónimo',
        category: 'Motivación',
      ),
      Quote(
        text: 'Los límites solo existen en tu mente.',
        author: 'Anónimo',
        category: 'Mentalidad',
      ),
      Quote(
        text: 'Hoy es un buen día para tener un buen día.',
        author: 'Anónimo',
        category: 'Bienestar',
      ),
      Quote(
        text: 'El progreso, no la perfección.',
        author: 'Anónimo',
        category: 'Motivación',
      ),
      Quote(
        text: 'Cada día es una nueva oportunidad.',
        author: 'Anónimo',
        category: 'Motivación',
      ),
    ];
  }
}
