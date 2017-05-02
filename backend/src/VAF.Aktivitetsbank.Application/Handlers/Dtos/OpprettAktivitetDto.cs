using System;
using System.ComponentModel.DataAnnotations;

namespace VAF.Aktivitetsbank.Application.Handlers.Dtos
{
    public class OpprettAktivitetDto
    {
        [Required]
        public Guid Id { get; set; }
        [Required]
        [StringLength(50, ErrorMessage = "Navn m� v�re mindre enn 50 tegn.")]
        public string Navn { get; set; }
        [Required]
        [StringLength(500, ErrorMessage = "Navn m� v�re mindre enn 500 tegn.")]
        public string Beskrivelse { get; set; }
        [Required]
        public int OmfangTimer { get; set; }
        [Required]
        public Guid SkoleId { get; set; }
        [Required]
        [StringLength(15, ErrorMessage = "Navn m� v�re mindre enn 15 tegn.")]
        public string Type { get; set; }
    }
}